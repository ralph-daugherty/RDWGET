      *****************************************************************
      *               RDWGET iSeries Scripted Web Retrieval
      *
      *  Program RDWGET
      *****************************************************************
     h dftactgrp(*no) actgrp('RDWRITES')
      /copy rdwgetsrc,rdwgeth

      *****************************************************************
      * File Specifications
      *****************************************************************
     frdwgetcfg if   e           k disk

      *****************************************************************
      * Prototype Definitions
      *****************************************************************
      /copy rdwgetsrc,rdwritespr
      /copy rdwgetsrc,rdwgetpr
      /copy rdwgetsrc,rdwapipr

     d rdwgetScript    pr                  like(boolean)
     d  prmScript                          like(rdwScript) const
     d  prmJobUser                         like(rdwUser) const

     d parseScript     pr                  like(boolean)
     d  prmScript                          like(rdwScript) const
     d  prmGetUser                         like(rdwUser) const
     d  prmScriptHnd                       like(int32) const
     d  prmErrPos                          like(charloc)

     d chkScriptAry    pr                  like(boolean)
     d  prmScript                          like(rdwScript) const
     d  prmErrCode                         like(rdwErrCode)

     d rmvScriptAry    pr
     d  prmScript                          like(rdwScript) const

      *****************************************************************
      * *Entry Declaration
      *****************************************************************
     d RDWGET          pr
     d  prmScript                          like(rdwScript)
     d RDWGET          pi
     d  prmScript                          like(rdwScript)

      *****************************************************************
      * Data Structure / Arrays Declaration
      *****************************************************************
     d scriptary       s                   like(rdwScript) dim(maxScript)
     d curScript       s              1  0 inz(0)
     d maxScript       c                   const(7)

      *****************************************************************
      * Stand Alone Fields Declaration
      *****************************************************************
     d prmJobUser      s                   like(rdwUser)
     d prmMsgCode      s                   like(rdwErrCode)

      *****************************************************************
      * Mainline
      *****************************************************************
      /free

         prmJobUser = rdwJobUser();
         *inlr = rdwgetScript(prmScript:
                              prmJobUser);
         if *inlr = *on;
           exsr exitProgram;
         endif;

         // audit script completion
         prmMsgCode = 'RDW0039';
         audScript(prmScript: prmMsgCode);

         // exit program
         exsr exitProgram;

       //**************************************************************
       //  Subroutine: exitProgram
       //**************************************************************
         begsr exitProgram;

           *inlr = *on;
           return;

         endsr;
      /end-free

       //**************************************************************
       //  Subprocedure: rdwgetScript
       //  Purpose:      recursive procedure to process RDWGET scripts.
       //    Arbitrarily limited to 7 levels, maxScript can be adjusted
       //    for a different limit. Check is made that included script
       //    is not already being processed to avoid concurrent conflicts.
       //  Parms:        prmScript    = RDWGET script name
       //                prmJobUser   = script user
       //  Returns:      isLR         = *on if fatal error
       //**************************************************************
       //
     p rdwgetScript    b
     d rdwgetScript    pi                  like(boolean)
     d  prmScript                          like(rdwScript) const
     d  prmJobUser                         like(rdwUser) const

       // local fields
     d isLR            s                   like(boolean)
     d isError         s                   like(boolean)
     d prmErrCode      s                   like(rdwErrCode)
     d prmErrPos       s                   like(charloc)
     d prmPath         s                   like(rdwPath)
     d ScriptPath      s                   like(nullPath)
     d ScriptHnd       s                   like(int32)

      /free
         isLR = *off;

         if chkScriptAry(prmScript: prmErrCode);
           // audit script level error
           return audScriptErr(prmScript: prmErrCode);
         endif;

         chain (prmScript) rdwgetcfg;
         if not %found(rdwgetcfg);
           // audit script key not found
           prmErrCode = 'RDW0015';
           return audScriptErr(prmScript: prmErrCode);
         endif;

         isError = rdwBldPath(scrpath:
                              scrsubdir:
                              scrfile:
                              prmScript:
                              prmJobUser:
                              prmPath:
                              prmErrPos);
         if isError = *on;
           return audParseErr(prmScript:
                              'RDW0018':
                              'SCRPATH':
                              prmErrPos);
         endif;

         %str(%addr(ScriptPath): (%len(ScriptPath)-1)) = %trimr(prmPath);
         ScriptHnd = rdwOpenIFS_RO(ScriptPath);
         if (ScriptHnd < *zeros);
           // audit script file not found
           prmErrCode = 'RDW0019';
           return audScriptErr(prmScript: prmErrCode);
         endif;

         isLR = parseScript(prmScript:
                            prmJobUser:
                            ScriptHnd:
                            prmErrPos);

         rdwCloseIFS(ScriptHnd);
         rmvScriptAry(prmScript);
         return isLR;

      /end-free
     p rdwgetScript    e

       //**************************************************************
       //  Subprocedure: parseScript
       //  Purpose:      procedure to parse RDWGET script
       //  Parms:        prmScript    = RDWGET script name
       //                prmJobUser   = job user
       //                prmScriptHnd = script file handle
       //                prmErrPos    = char position of error
       //  Returns:      isError      = *on if error
       //**************************************************************
       //
     p parseScript     b
     d parseScript     pi                  like(boolean)
     d  prmScript                          like(rdwScript) const
     d  prmJobUser                         like(rdwUser) const
     d  prmScriptHnd                       like(int32) const
     d  prmErrPos                          like(charloc)

       // local fields
     d                 ds
     d  scrData                            like(rdwFileBuf)
     d  scrary                             like(charval) dim(%size(scrData))
     d                                     overlay(scrData: 1)
     d scrlen          s                   like(charloc) inz(*zeros)
     d scridx          s                   like(charloc) inz(1)
     d requestlen      s                   like(uint32) inz(%size(scrData))
     d readlen         s                   like(int32)
     d readPtr         s                   like(basePtr) inz(%addr(scrData))
     d readState       s                   like(rdwState) inz(SeekOpcode)
     d scrEOF          s                   like(boolean) inz(*off)
     d evalchar        s                   like(charval)
     d linepos         s                   like(charloc) inz(1)
     d charpos         s                   like(charloc) inz(*zeros)
     d linePhase       s                   like(rdwState) inz(StartPhase)

     d                 ds
     d  fldData                            like(rdwField)
     d  fldary                             like(charval) dim(%size(fldData))
     d                                     overlay(fldData: 1)
     d fldlen          s                   like(charloc) inz(%size(fldData))
     d fldidx          s                   like(charloc) inz(*zeros)
     d fldUpped        s                   like(rdwField)

     d                 ds
     d  fncData                            like(rdwPath)
     d  fncary                             like(charval) dim(%size(fncData))
     d                                     overlay(fncData: 1)
     d fnclen          s                   like(charloc) inz(%size(fncData))
     d fncidx          s                   like(charloc) inz(*zeros)
     d fncUpped        s                   like(rdwPath)

     d                 ds
     d  argData                            like(rdwPath)
     d  argary                             like(charval) dim(%size(argData))
     d                                     overlay(argData: 1)
     d arglen          s                   like(charloc) inz(%size(argData))
     d argidx          s                   like(charloc) inz(*zeros)
     d arglvl          s                   like(charloc)
     d argpos          s                   like(charloc)
     d argparse        s                   like(charloc)

     d                 ds
     d  oprData                            like(rdwOperand)
     d  oprary                             like(charval) dim(%size(oprData))
     d                                     overlay(oprData: 1)
     d oprlen          s                   like(charloc) inz(%size(oprData))
     d opridx          s                   like(charloc) inz(*zeros)
     d oprlvl          s                   like(charloc)

     d                 ds
     d  strData                            like(rdwOperand)
     d  strary                             like(charval) dim(%size(strData))
     d                                     overlay(strData: 1)
     d strlen          s                   like(charloc) inz(%size(strData))
     d stridx          s                   like(charloc) inz(*zeros)

     d                 ds
     d  wrkData                            like(rdwFileBuf)
     d  wrkary                             like(charval) dim(%size(wrkData))
     d                                     overlay(wrkData: 1)
     d wrklen          s                   like(charloc) inz(*zeros)
     d wrkidx          s                   like(charloc) inz(1)
     d wrkRequest      s                   like(uint32) inz(%size(wrkData))
     d wrkRead         s                   like(int32)
     d wrkPtr          s                   like(basePtr) inz(%addr(wrkData))
     d wrkEOF          s                   like(boolean) inz(*off)
     d WorkPath        s                   like(nullPath)
     d WorkHnd         s                   like(int32) inz(*zeros)

     d                 ds
     d  cmpData                            like(rdwCmpBuf)
     d  cmpary                             like(charval) dim(%size(cmpData))
     d                                     overlay(cmpData: 1)
     d cmplen          s                   like(charloc) inz(%size(cmpData))
     d cmpidx          s                   like(charloc) inz(1)
     d mchidx          s                   like(charloc)
     d cmpFound        s                   like(boolean)
     d prmFound        s                   like(boolean)
     d prmFndSrc       s                   like(rdwField)
     d prmFndState     s                   like(rdwState)

     d                 ds
     d  stpData                            like(rdwCmpBuf)
     d  stpary                             like(charval) dim(%size(stpData))
     d                                     overlay(stpData: 1)
     d stplen          s                   like(charloc) inz(%size(stpData))
     d stpidx          s                   like(charloc) inz(1)

     d                 ds
     d  varData                            like(rdwCmpBuf)
     d  varary                             like(charval) dim(%size(varData))
     d                                     overlay(varData: 1)
     d varlen          s                   like(charloc) inz(%size(varData))
     d varidx          s                   like(charloc) inz(1)

     d prmGetUser      s                   like(rdwUser)
     d prmWorkPath     s                   like(rdwPath)
     d prmOutPath      s                   like(rdwPath)
     d prmGetPath      s                   like(rdwPath)
     d prmOpcode       s                   like(rdwField)
     d prmSetVarKey    s                   like(rdwField)
     d prmGetVarKey    s                   like(rdwField)
     d needResult      s                   like(boolean)
     d needEqual       s                   like(boolean)
     d needOperand     s                   like(boolean)
     d needArgs        s                   like(boolean)
     d haveSetVar      s                   like(boolean)
     d haveGetVar      s                   like(boolean)
     d haveString      s                   like(boolean)
     d haveFunc        s                   like(boolean)
     d haveArgs        s                   like(boolean)
     d haveSlash       s                   like(boolean)
     d charAdded       s                   like(boolean)
     d setFormAry      s                   like(rdwCmpBuf)
     d                                     dim(rdwFormMax)
     d setFormVal      s                   like(rdwPath)
     d                                     dim(rdwFormMax)
     d setFormIdx      s                   like(rdwState) inz(*zeros)

     d isError         s                   like(boolean) inz(*off)
     d prmErrCode      s                   like(rdwErrCode)
     d lineErrPos      s                   like(rdwField)

      /free

         chain (prmScript) rdwgetcfg;
         if not %found(rdwgetcfg);
           // audit script key not found
           prmErrCode = 'RDW0015';
           return audScriptErr(prmScript: prmErrCode);
         endif;

         isError = rdwBldPath(wrkpath:
                              wrksubdir:
                              wrkfile:
                              prmScript:
                              prmJobUser:
                              prmWorkPath:
                              prmErrPos);
         if isError = *on;
           return audParseErr(prmScript:
                              'RDW0018':
                              'WRKPATH':
                              prmErrPos);
         endif;

         isError = rdwBldPath(outpath:
                              outsubdir:
                              outfile:
                              prmScript:
                              prmJobUser:
                              prmOutPath:
                              prmErrPos);
         if isError = *on;
           return audParseErr(prmScript:
                              'RDW0018':
                              'OUTPATH':
                              prmErrPos);
         endif;

         prmGetUser = prmJobUser;
         exsr loadScrData;

         dow readState <> ExitState;
           select;
             when readState = SeekOpcode;
               exsr parseOpcode;

             when readState = SeekResult;
               exsr parseResult;

             when readState = SeekEqual;
               exsr parseEqual;

             when readState = SeekOperand;
               exsr parseOperand;

             when readState = SeekWhite;
               exsr parseWhite;

             when readState = SeekEOL;
               exsr parseEOL;

             when readState = ExitState;
               leave;

             other;
               // undefined read state
               prmErrCode = 'RDW0036';
               exsr parseScriptErr;
           endsl;
         enddo;

         if WorkHnd > *zeros;
           rdwCloseIFS(WorkHnd);
         endif;

         return isError;

       //**************************************************************
       //  Subroutine: parse for opcode field
       //**************************************************************
         begsr parseOpcode;

           fldData = *blanks;
           fldidx = *zeros;

           dow readState = SeekOpcode;
             dow scridx <= scrlen;
               evalchar = scrary(scridx);
               select;
                 when haveSlash = *on;
                   if evalchar = Slash;
                     charpos += 1;
                     scridx += 1;
                     haveSlash = *off;
                     readState = SeekEOL;
                     linePhase = CommentPhase;
                     leavesr;
                   else;
                     // unexpected slash parse error
                     prmErrCode = 'RDW0027';
                     charpos -= 1;
                     exsr parseScriptErr;
                     leavesr;
                   endif;

                 when evalchar = Slash;
                   if fldidx = *zeros;
                     haveSlash = *on;
                     charpos += 1;
                     scridx += 1;
                   else;
                     // unexpected slash parse error
                     prmErrCode = 'RDW0027';
                     exsr parseScriptErr;
                     leavesr;
                   endif;

                 when evalchar = rdwCR
                   or evalchar = rdwLF;
                   if fldidx = *zeros;
                     exsr parseCRLF;
                   else;
                     // unexpected EOL parse error
                     prmErrCode = 'RDW0028';
                     exsr parseScriptErr;
                     leavesr;
                   endif;

                 when evalchar = Colon;
                   if linePhase = StartPhase
                     and fldidx > *zeros;
                     charpos += 1;
                     scridx += 1;
                     linePhase = OpcodePhase;
                     fldData = *blanks;
                     fldidx = *zeros;
                   else;
                     // unexpected label parse error
                     prmErrCode = 'RDW0023';
                     exsr parseScriptErr;
                     leavesr;
                   endif;

                 when evalchar <= nonbrkBlank;
                   if fldidx = *zeros;
                     charpos += 1;
                     scridx += 1;
                   else;
                     exsr evalOpcode;
                     leavesr;
                   endif;

                 other;
                   exsr chkFieldAdd;
                   if charAdded = *off
                     and readState <> ExitState;
                     // unexpected special character parse error
                     prmErrCode = 'RDW0020';
                     exsr parseScriptErr;
                     leavesr;
                   endif;
               endsl;
             enddo;

             if readState = SeekOpcode;
               exsr loadScrData;
             endif;
           enddo;

         endsr;

       //**************************************************************
       //  Subroutine: evaluate field for opcode
       //**************************************************************
         begsr evalOpcode;

           exsr initLineParms;
           fldUpped = %xlate(rdwLower: rdwUpper: fldData);
           select;
             when fldUpped = 'EVAL';
               prmOpcode = fldUpped;
               readState = SeekResult;
               linePhase = ResultPhase;
               needResult = *on;
               needEqual = *on;
               needOperand = *on;

             when fldUpped = 'GET';
               prmOpcode = fldUpped;
               readState = SeekOperand;
               linePhase = OperandPhase;
               needOperand = *on;

             when fldUpped = 'FIND';
               prmOpcode = fldUpped;
               readState = SeekOperand;
               linePhase = OperandPhase;
               needOperand = *on;

             when fldUpped = 'SETVAR';
               prmOpcode = fldUpped;
               readState = SeekOperand;
               linePhase = OperandPhase;
               needOperand = *on;

             when fldUpped = 'POST';
               prmOpcode = fldUpped;
               readState = SeekOperand;
               linePhase = OperandPhase;
               needOperand = *on;

             when fldUpped = 'INCLUDE';
               prmOpcode = fldUpped;
               readState = SeekOperand;
               linePhase = OperandPhase;
               needOperand = *on;

             when fldUpped = 'END';
               readState = ExitState;

             other;
               // unsupported opcode parse error
               prmErrCode = 'RDW0025';
               charpos -= (%len(%trimr(fldData))-1);
               exsr parseScriptErr;
           endsl;

         endsr;

       //**************************************************************
       //  Subroutine: execute opcode
       //**************************************************************
         begsr execOpcode;

           select;
             when prmOpcode = 'EVAL';
               if readState = ExitState;
                 leavesr;
               endif;
               setRDWvar(prmScript:
                         prmGetUser:
                         prmSetVarKey:
                         oprData);


             when prmOpcode = 'GET';
               exsr evalGet;
               if readState = ExitState
                 or linePhase = OperandPhase;
                 leavesr;
               endif;
               isError = rdwGetURL(prmScript:
                                   prmGetUser:
                                   prmGetPath:
                                   oprData);
               if isError = *on;
                 readState = ExitState;
                 leavesr;
               endif;
               exsr openGetPath;
               linePhase = OperandPhase;


             when prmOpcode = 'FIND';
               prmFound = *off;
               exsr evalFind;
               if readState = ExitState
                 or linePhase = OperandPhase;
                 leavesr;
               endif;
               exsr execFind;
               if readState = ExitState;
                 leavesr;
               endif;
               prmFound = cmpFound;
               if prmFound = *off;
                 // required string not found error
                 prmErrCode = 'RDW0038';
                 exsr parseScriptErr;
                 leavesr;
               endif;
               linePhase = OperandPhase;


             when prmOpcode = 'SETVAR';
               exsr evalSetVar;
               if readState = ExitState
                 or linePhase = OperandPhase;
                 leavesr;
               endif;
               exsr execSetVar;
               if readState = ExitState;
                 leavesr;
               endif;
               linePhase = OperandPhase;


             when prmOpcode = 'POST';
               exsr evalPost;
               if readState = ExitState
                 or linePhase = OperandPhase;
                 leavesr;
               endif;
               isError = rdwPostURL(prmScript:
                                    prmGetUser:
                                    prmGetPath:
                                    setFormAry:
                                    setFormVal:
                                    setFormIdx:
                                    oprData);
               if isError = *on;
                 readState = ExitState;
                 leavesr;
               endif;
               setFormIdx = *zeros;
               exsr openGetPath;
               linePhase = OperandPhase;


             when prmOpcode = 'INCLUDE';
               if readState = ExitState;
                 leavesr;
               endif;
               isError = rdwgetScript(%trimr(oprData):
                                      prmGetUser);
               if isError = *on;
                 readState = ExitState;
                 leavesr;
               endif;


             other;
               // unsupported opcode parse error
               prmErrCode = 'RDW0025';
               exsr parseScriptErr;
           endsl;

         endsr;

       //**************************************************************
       //  Subroutine: init line opcode parm store
       //**************************************************************
         begsr initLineParms;

           prmOpcode = *blanks;
           prmSetVarKey = *blanks;
           needResult = *off;
           needEqual = *off;
           needOperand = *off;
           haveSetVar = *off;
           haveGetVar = *off;
           haveString = *off;
           haveFunc = *off;
           prmFndSrc = *blanks;
           prmGetPath = *blanks;
           oprlvl = *zeros;

         endsr;

       //**************************************************************
       //  Subroutine: parse for result field
       //**************************************************************
         begsr parseResult;

           fldData = *blanks;
           fldidx = *zeros;

           dow readState = SeekResult;
             dow scridx <= scrlen;
               evalchar = scrary(scridx);
               select;
                 when evalchar = rdwCR
                   or evalchar = rdwLF;
                   // unexpected EOL parse error
                   prmErrCode = 'RDW0028';
                   exsr parseScriptErr;
                   leavesr;

                 when evalchar = Ampersand;
                   if linePhase = ResultPhase;
                     charpos += 1;
                     scridx += 1;
                     haveSetVar = *on;
                     linePhase = FieldPhase;
                     fldData = *blanks;
                     fldidx = *zeros;
                   else;
                     // unexpected '&' parse error
                     prmErrCode = 'RDW0024';
                     exsr parseScriptErr;
                     leavesr;
                   endif;

                 when evalchar <= nonbrkBlank;
                   if fldidx = *zeros
                     and linePhase = ResultPhase;
                     charpos += 1;
                     scridx += 1;
                   else;
                     exsr evalResult;
                     leavesr;
                   endif;

                 other;
                   exsr chkFieldAdd;
                   if charAdded = *off
                     and readState <> ExitState;
                     // unexpected special character parse error
                     prmErrCode = 'RDW0020';
                     exsr parseScriptErr;
                     leavesr;
                   endif;
               endsl;
             enddo;

             if readState = SeekResult;
               exsr loadScrData;
             endif;
           enddo;

         endsr;

       //**************************************************************
       //  Subroutine: evaluate field for result
       //**************************************************************
         begsr evalResult;

           select;
             when haveSetVar = *on;
               select;
                 when fldidx = *zeros;
                   // unexpected '&' parse error
                   prmErrCode = 'RDW0024';
                   exsr parseScriptErr;

                 other;
                   prmSetVarKey = fldData;
                   needResult = *off;
                   readState = SeekEqual;
                   linePhase = EqualityPhase;
               endsl;

             other;
               // unsupported result field parse error
               prmErrCode = 'RDW0026';
               charpos -= (%len(%trimr(fldData))-1);
               exsr parseScriptErr;
           endsl;

         endsr;

       //**************************************************************
       //  Subroutine: parse for equal sign
       //**************************************************************
         begsr parseEqual;

           fldData = *blanks;
           fldidx = *zeros;

           dow readState = SeekEqual;
             dow scridx <= scrlen;
               evalchar = scrary(scridx);
               select;
                 when evalchar = rdwCR
                   or evalchar = rdwLF;
                   // unexpected EOL parse error
                   prmErrCode = 'RDW0028';
                   exsr parseScriptErr;
                   leavesr;

                 when evalchar = rdwEqual;
                   charpos += 1;
                   scridx += 1;
                   needEqual = *off;
                   readState = SeekOperand;
                   linePhase = OperandPhase;
                   leavesr;

                 when evalchar <= nonbrkBlank;
                   if fldidx = *zeros
                     and linePhase = EqualityPhase;
                     charpos += 1;
                     scridx += 1;
                   else;
                     // unexpected special character parse error
                     prmErrCode = 'RDW0020';
                     exsr parseScriptErr;
                     leavesr;
                   endif;

                 other;
                   exsr chkFieldAdd;
                   if charAdded = *off
                     and readState <> ExitState;
                     // unexpected special character parse error
                     prmErrCode = 'RDW0020';
                     exsr parseScriptErr;
                     leavesr;
                   endif;
               endsl;
             enddo;

             if readState = SeekResult;
               exsr loadScrData;
             endif;
           enddo;

         endsr;

       //**************************************************************
       //  Subroutine: parse opcode operand
       //**************************************************************
         begsr parseOperand;

           oprData = *blanks;
           opridx = *zeros;

           dow readState = SeekOperand;
             dow scridx <= scrlen;
               evalchar = scrary(scridx);
               select;
                 when haveSlash = *on;
                   if evalchar = Slash;
                     charpos += 1;
                     scridx += 1;
                     haveSlash = *off;
                     exsr evalOperand;
                     if readState = ExitState;
                       leavesr;
                     endif;
                     exsr execOpcode;
                     if readState = ExitState;
                       leavesr;
                     endif;
                     readState = SeekEOL;
                     linePhase = CommentPhase;
                     leavesr;
                   else;
                     // unexpected slash parse error
                     prmErrCode = 'RDW0027';
                     charpos -= 1;
                     exsr parseScriptErr;
                     leavesr;
                   endif;

                 when linePhase = StringPhase;
                   select;
                     when evalchar = Quote;
                       oprData = %trimr(oprData) +
                                 %subst(strData: 1: stridx);
                       charpos += 1;
                       scridx += 1;
                       opridx += stridx;
                       haveString = *on;
                       linePhase = OperandPhase;

                     when evalchar < Blank;
                       // unexpected string parse error
                       prmErrCode = 'RDW0029';
                       exsr parseScriptErr;
                       leavesr;

                     other;
                       exsr chkStringAdd;
                       if charAdded = *off;
                         leavesr;
                       endif;
                   endsl;

                 when linePhase = FieldPhase;
                   select;
                     when evalchar <= nonbrkBlank
                       or evalchar = RightParen;
                       prmGetVarKey = fldData;
                       oprData = %trimr(oprData) +
                                 %trimr(getRDWvar(prmScript:
                                        prmGetUser:
                                        prmGetVarKey));
                       haveGetVar = *on;
                       linePhase = OperandPhase;

                     other;
                       exsr chkFieldAdd;
                       if charAdded = *off
                         and readState <> ExitState;
                         // unexpected special character parse error
                         prmErrCode = 'RDW0020';
                         exsr parseScriptErr;
                         leavesr;
                       endif;
                   endsl;

                 when linePhase = FuncPhase;
                   select;
                     when evalchar <= nonbrkBlank
                       or evalchar = LeftParen;
                       exsr evalFuncCode;
                       if readState = ExitState;
                         leavesr;
                       endif;

                     other;
                       exsr chkFuncAdd;
                       if readState = ExitState;
                         leavesr;
                       endif;
                       select;
                         when charAdded = *on;
                           scridx += 1;
                           charpos += 1;

                         when charAdded = *off
                           and readState <> ExitState;
                           // unexpected special character parse error
                           prmErrCode = 'RDW0020';
                           exsr parseScriptErr;
                           leavesr;
                       endsl;
                   endsl;

                 when linePhase = OperandPhase
                   or linePhase = ContinuePhase;
                   select;
                     when evalchar = Slash;
                       haveSlash = *on;
                       charpos += 1;
                       scridx += 1;

                     when evalchar = LeftParen;
                       oprlvl += 1;
                       charpos += 1;
                       scridx += 1;
                       exsr execOpcode;
                       if readState = ExitState;
                         leavesr;
                       endif;

                     when evalchar = RightParen;
                       oprlvl -= 1;
                       charpos += 1;
                       scridx += 1;

                     when evalchar = Quote;
                       charpos += 1;
                       scridx += 1;
                       linePhase = StringPhase;
                       strData = *blanks;
                       stridx = *zeros;

                     when evalchar = Ampersand;
                       charpos += 1;
                       scridx += 1;
                       linePhase = FieldPhase;
                       fldData = *blanks;
                       fldidx = *zeros;

                     when evalchar = Percent;
                       charpos += 1;
                       scridx += 1;
                       linePhase = FuncPhase;
                       fncData = *blanks;
                       fncidx = *zeros;

                     when evalchar = rdwPlus;
                       select;
                         when linePhase = OperandPhase;
                           charpos += 1;
                           scridx += 1;
                           linePhase = ContinuePhase;

                         other;
                           // unexpected '+' parse error
                           prmErrCode = 'RDW0030';
                           exsr parseScriptErr;
                           leavesr;
                       endsl;

                     when evalchar = rdwCR
                       or evalchar = rdwLF;
                       select;
                         when linePhase = OperandPhase;
                           exsr evalOperand;
                           if readState = ExitState;
                             leavesr;
                           endif;
                           exsr execOpcode;
                           readState = SeekWhite;
                           linePhase = WhitePhase;
                           leavesr;

                         when linePhase = ContinuePhase;
                           exsr parseCRLF;
                       endsl;

                     when evalchar <= nonbrkBlank;
                       charpos += 1;
                       scridx += 1;

                     other;
                       // unexpected operand parse error
                       prmErrCode = 'RDW0031';
                       exsr parseScriptErr;
                       leavesr;
                   endsl;

                 other;
                   // unexpected operand parse error
                   prmErrCode = 'RDW0031';
                   exsr parseScriptErr;
                   leavesr;
               endsl;
             enddo;

             if readState = SeekOperand;
               exsr loadScrData;
             endif;
           enddo;

         endsr;

       //**************************************************************
       //  Subroutine: evaluate operand
       //**************************************************************
         begsr evalOperand;

           if opridx = *zeros
             and haveGetVar = *off
             and haveFunc = *off
             and haveArgs = *off
             and haveString = *off;
             // unexpected operand parse error
             prmErrCode = 'RDW0031';
             exsr parseScriptErr;
             leavesr;
           endif;

           needOperand = *off;

         endsr;

       //**************************************************************
       //  Subroutine: evaluate field for function
       //**************************************************************
         begsr evalFuncCode;

           fncUpped = %xlate(rdwLower: rdwUpper: fncData);
           select;
             when fncUpped = 'RDWSCRIPT';
               oprData = %trimr(oprData) + %trimr(prmScript);

             when fncUpped = 'RDWUSER';
               oprData = %trimr(oprData) + %trimr(prmGetUser);

             when fncUpped = 'QUOTE';
               oprData = %trimr(oprData) + Quote;

             when fncUpped = 'RDWSUBST';
               exsr evalRdwSubst;
               if prmFound = *off;
                 // required string not found error
                 prmErrCode = 'RDW0038';
                 exsr parseScriptErr;
                 leavesr;
               endif;

             other;
               // unsupported function parse error
               prmErrCode = 'RDW0034';
               charpos -= (%len(%trimr(fncData))-1);
               exsr parseScriptErr;
               leavesr;
           endsl;

           haveFunc = *on;
           linePhase = OperandPhase;

         endsr;

       //**************************************************************
       //  Subroutine: eval Substring function
       //**************************************************************
         begsr evalRdwSubst;

           linePhase = ArgsPhase;
           exsr parseArgs;
           if readState = ExitState;
             leavesr;
           endif;

           // parse for source of args
           exsr parseArgSrc;
           if readState = ExitState;
             leavesr;
           endif;

           // parse for arg compare string
           exsr parseArgCmp;
           if readState = ExitState;
             leavesr;
           endif;

           // parse for arg stop string
           exsr parseArgStop;
           if readState = ExitState;
             leavesr;
           endif;

           exsr execRdwSubst;
           prmFound = cmpFound;
           if prmFound = *off;
             charpos = argparse;
             leavesr;
           endif;

           // parse for args end
           exsr parseArgEnd;

         endsr;

       //**************************************************************
       //  Subroutine: exec Substring function
       //**************************************************************
         begsr execRdwSubst;

           prmFndState = ResultPhase;
           exsr execFind;
           if cmpFound = *off;
             leavesr;
           endif;

           cmpData = stpData;
           cmpFound = *off;
           cmpidx = stpidx;
           mchidx = 1;
           select;
             when prmFndSrc = 'WRKPATH';
               dow prmFndState = ContinuePhase;
                 dow wrkidx <= wrklen;
                   opridx += 1;
                   oprary(opridx) = wrkary(wrkidx);
                   if cmpary(mchidx) =
                      %xlate(rdwLower: rdwUpper: wrkary(wrkidx));
                     wrkidx += 1;
                     if mchidx = cmpidx;
                       // found compare string in work file
                       cmpFound = *on;
                       prmFndState = ResultPhase;
                       for mchidx = cmpidx downto 1;
                         oprary(opridx) = *blanks;
                         opridx -= 1;
                       endfor;
                       leave;
                     else;
                       mchidx += 1;
                     endif;
                   else;
                     if mchidx > 1;
                       mchidx = 1;
                       opridx -= 1;
                     else;
                       wrkidx += 1;
                     endif;
                   endif;
                 enddo;

                 if readState <> ExitState;
                   exsr loadWrkData;
                 endif;
               enddo;

             other;
               // unexpected args parse error
               prmErrCode = 'RDW0035';
               exsr parseScriptErr;
               leavesr;
           endsl;

         endsr;

       //**************************************************************
       //  Subroutine: parse opcode args
       //**************************************************************
         begsr parseArgs;

           argData = *blanks;
           argidx = *zeros;
           arglvl = *zeros;
           haveArgs = *off;

           dow readState = SeekOperand;
             dow scridx <= scrlen;
               evalchar = scrary(scridx);
               select;
                 when evalchar = rdwCR
                   or evalchar = rdwLF;
                   // unexpected EOL parse error
                   prmErrCode = 'RDW0028';
                   exsr parseScriptErr;
                   leavesr;

                 when linePhase = ArgsPhase;
                   select;
                     when evalchar = LeftParen;
                       argpos = charpos;
                       arglvl = *zeros;
                       linePhase = StringPhase;

                     when evalchar <= nonbrkBlank;
                       charpos += 1;
                       scridx += 1;

                     other;
                       // unexpected argument parse error
                       prmErrCode = 'RDW0035';
                       exsr parseScriptErr;
                       leavesr;
                   endsl;

                 when linePhase = StringPhase;
                   if evalchar = LeftParen;
                     arglvl += 1;
                   endif;

                   if evalchar = RightParen;
                     arglvl -= 1;
                   endif;

                   select;
                     when evalchar < Blank;
                       // unexpected argument parse error
                       prmErrCode = 'RDW0035';
                       exsr parseScriptErr;
                       leavesr;

                     other;
                       exsr chkArgsAdd;
                       if charAdded = *off;
                         leavesr;
                       endif;
                       if arglvl = *zeros;
                         // have reached closing paren of args
                         needArgs = *off;
                         haveArgs = *on;
                         leavesr;
                       endif;
                   endsl;
               endsl;
             enddo;

             if readState = SeekOperand;
               exsr loadScrData;
             endif;
           enddo;

         endsr;

       //**************************************************************
       //  Subroutine: parse for args source
       //**************************************************************
         begsr parseArgSrc;

           argidx = 1;
           argparse = argpos;
           dow argidx <= arglen;
             evalchar = argary(argidx);
             select;
               when evalchar = LeftParen;
                 argidx += 1;
                 leave;
               when evalchar <= nonbrkBlank;
                 argidx += 1;
               other;
                 // unexpected args parse error
                 prmErrCode = 'RDW0035';
                 charpos = argpos + argidx;
                 exsr parseScriptErr;
                 leavesr;
             endsl;
           enddo;

           if argidx > arglen;
             // unexpected args parse error
             prmErrCode = 'RDW0035';
             charpos = argparse;
             exsr parseScriptErr;
             leavesr;
           endif;

           // parse for arg source
           fldData = *blanks;
           fldidx = *zeros;
           argparse = argpos + argidx;
           prmFndSrc = *blanks;
           dow argidx <= arglen;
             evalchar = argary(argidx);
             select;
               when evalchar <= nonbrkBlank;
                 leave;
               when evalchar = Colon;
                 leave;
               other;
                 if fldidx < fldlen;
                   fldidx += 1;
                   fldary(fldidx) = evalchar;
                   argidx += 1;
                 else;
                   // field exceeds rdwField length parse error
                   prmErrCode = 'RDW0021';
                   charpos = argparse;
                   exsr parseScriptErr;
                   leavesr;
                 endif;
             endsl;
           enddo;

           if argidx > arglen;
             // unexpected args parse error
             prmErrCode = 'RDW0035';
             charpos = argparse;
             exsr parseScriptErr;
             leavesr;
           endif;

           fldUpped = %xlate(rdwLower: rdwUpper: fldData);
           select;
             when %trimr(fldUpped) = 'WRKPATH';
               prmFndSrc = 'WRKPATH';
             other;
               // unexpected args parse error
               prmErrCode = 'RDW0035';
               charpos = argparse;
               exsr parseScriptErr;
               leavesr;
           endsl;

           // parse for arg colon separator
           exsr parseArgColon;

         endsr;

       //**************************************************************
       //  Subroutine: parse for arg colon separator
       //**************************************************************
         begsr parseArgColon;

           // parse for Colon separator
           argparse = argpos + argidx;
           dow argidx <= arglen;
             evalchar = argary(argidx);
             select;
               when evalchar <= nonbrkBlank;
                 argidx += 1;
               when evalchar = Colon;
                 argidx += 1;
                 leave;
               other;
                 // unexpected args parse error
                 prmErrCode = 'RDW0035';
                 charpos = argpos + argidx;
                 exsr parseScriptErr;
                 leavesr;
             endsl;
           enddo;

           if argidx > arglen;
             // unexpected args parse error
             prmErrCode = 'RDW0035';
             charpos = argparse;
             exsr parseScriptErr;
             leavesr;
           endif;

         endsr;

       //**************************************************************
       //  Subroutine: parse for arg compare string
       //**************************************************************
         begsr parseArgCmp;

           // parse for arg compare type
           exsr parseArgType;
           if readState = ExitState;
             leavesr;
           endif;

           // parse for compare string
           cmpData = *blanks;
           cmpidx = *zeros;
           argparse = argpos + argidx;
           select;
             when prmFndState = StringPhase;
               dow argidx <= arglen;
                 evalchar = argary(argidx);
                 select;
                   when evalchar = Quote;
                     prmFndState = ResultPhase;
                     argidx += 1;
                     leave;

                   when evalchar < Blank;
                     // unexpected args parse error
                     prmErrCode = 'RDW0035';
                     charpos = argpos + argidx;
                     exsr parseScriptErr;
                     leavesr;

                   other;
                     if cmpidx < cmplen;
                       cmpidx += 1;
                       cmpary(cmpidx) = %xlate(rdwLower: rdwUpper: evalchar);
                       argidx += 1;
                     else;
                       // field exceeds rdwField length parse error
                       prmErrCode = 'RDW0021';
                       charpos = argparse;
                       exsr parseScriptErr;
                       leavesr;
                     endif;
                 endsl;
               enddo;

             when prmFndState = FuncPhase;
               dow argidx <= arglen;
                 evalchar = argary(argidx);
                 select;
                   when evalchar <= nonbrkBlank
                     or evalchar = Colon
                     or evalchar = RightParen;
                     fncUpped = %xlate(rdwLower: rdwUpper: fncData);
                     select;
                       when fncUpped = 'QUOTE';
                         cmpidx += 1;
                         cmpary(cmpidx) = Quote;
                         leave;

                       other;
                         // unsupported function parse error
                         prmErrCode = 'RDW0034';
                         charpos -= (%len(%trimr(fncData))-1);
                         exsr parseScriptErr;
                         leavesr;
                     endsl;

                   other;
                     exsr chkFuncAdd;
                     if readState = ExitState;
                       leavesr;
                     endif;
                     select;
                       when charAdded = *on;
                         argidx += 1;

                       when charAdded = *off
                         and readState <> ExitState;
                         // unexpected special character parse error
                         prmErrCode = 'RDW0020';
                         exsr parseScriptErr;
                         leavesr;
                     endsl;
                 endsl;
               enddo;

             other;
               // unexpected args parse error
               prmErrCode = 'RDW0035';
               charpos = argparse;
               exsr parseScriptErr;
               leavesr;
           endsl;

           if argidx > arglen;
             // unexpected args parse error
             prmErrCode = 'RDW0035';
             charpos = argparse;
             exsr parseScriptErr;
             leavesr;
           endif;

         endsr;

       //**************************************************************
       //  Subroutine: parse for arg compare type
       //**************************************************************
         begsr parseArgType;

           // parse for compare type
           prmFndState = StartPhase;
           argparse = argpos + argidx;
           dow argidx <= arglen;
             evalchar = argary(argidx);
             select;
               when evalchar <= nonbrkBlank;
                 argidx += 1;

               when evalchar = Quote;
                 prmFndState = StringPhase;
                 argidx += 1;
                 leavesr;

               when evalchar = Percent;
                 argidx += 1;
                 prmFndState = FuncPhase;
                 fncData = *blanks;
                 fncidx = *zeros;
                 leavesr;

               other;
                 // unexpected args parse error
                 prmErrCode = 'RDW0035';
                 charpos = argparse;
                 exsr parseScriptErr;
                 leavesr;
             endsl;
           enddo;

           if argidx > arglen;
             // unexpected args parse error
             prmErrCode = 'RDW0035';
             charpos = argparse;
             exsr parseScriptErr;
             leavesr;
           endif;

         endsr;

       //**************************************************************
       //  Subroutine: parse for arg stop string
       //**************************************************************
         begsr parseArgStop;

           // parse for arg colon separator
           exsr parseArgColon;
           if readState = ExitState;
             leavesr;
           endif;

           // parse for arg compare type
           exsr parseArgType;
           if readState = ExitState;
             leavesr;
           endif;

           // parse for stop string
           stpData = *blanks;
           stpidx = *zeros;
           argparse = argpos + argidx;
           select;
             when prmFndState = StringPhase;
               dow argidx <= arglen;
                 evalchar = argary(argidx);
                 select;
                   when evalchar = Quote;
                     prmFndState = ResultPhase;
                     argidx += 1;
                     leave;

                   when evalchar < Blank;
                     // unexpected args parse error
                     prmErrCode = 'RDW0035';
                     charpos = argpos + argidx;
                     exsr parseScriptErr;
                     leavesr;

                   other;
                     if stpidx < stplen;
                       stpidx += 1;
                       stpary(stpidx) = %xlate(rdwLower: rdwUpper: evalchar);
                       argidx += 1;
                     else;
                       // field exceeds rdwField length parse error
                       prmErrCode = 'RDW0021';
                       charpos = argparse;
                       exsr parseScriptErr;
                       leavesr;
                     endif;
                 endsl;
               enddo;

             when prmFndState = FuncPhase;
               dow argidx <= arglen;
                 evalchar = argary(argidx);
                 select;
                   when evalchar <= nonbrkBlank
                     or evalchar = Colon
                     or evalchar = RightParen;
                     fncUpped = %xlate(rdwLower: rdwUpper: fncData);
                     select;
                       when fncUpped = 'QUOTE';
                         stpidx += 1;
                         stpary(stpidx) = Quote;
                         leave;

                       other;
                         // unsupported function parse error
                         prmErrCode = 'RDW0034';
                         charpos -= (%len(%trimr(fncData))-1);
                         exsr parseScriptErr;
                         leavesr;
                     endsl;

                   other;
                     exsr chkFuncAdd;
                     if readState = ExitState;
                       leavesr;
                     endif;
                     select;
                       when charAdded = *on;
                         argidx += 1;

                       when charAdded = *off
                         and readState <> ExitState;
                         // unexpected special character parse error
                         prmErrCode = 'RDW0020';
                         exsr parseScriptErr;
                         leavesr;
                     endsl;
                 endsl;
               enddo;

             other;
               // unexpected args parse error
               prmErrCode = 'RDW0035';
               charpos = argparse;
               exsr parseScriptErr;
               leavesr;
           endsl;

           if argidx > arglen;
             // unexpected args parse error
             prmErrCode = 'RDW0035';
             charpos = argparse;
             exsr parseScriptErr;
             leavesr;
           endif;

         endsr;

       //**************************************************************
       //  Subroutine: parse for args end
       //**************************************************************
         begsr parseArgEnd;

           // parse for end of args
           argparse = argpos + argidx;
           dow argidx <= arglen;
             evalchar = argary(argidx);
             select;
               when evalchar = RightParen;
                 prmFndState = EOLPhase;
                 argidx += 1;
                 leave;
               when evalchar <= nonbrkBlank;
                 argidx += 1;
               other;
                 // unexpected args parse error
                 prmErrCode = 'RDW0035';
                 charpos = argpos + argidx;
                 exsr parseScriptErr;
                 leavesr;
             endsl;
           enddo;

           if prmFndState <> EOLPhase;
             // unexpected args parse error
             prmErrCode = 'RDW0035';
             charpos = argparse;
             exsr parseScriptErr;
             leavesr;
           endif;

         endsr;

       //**************************************************************
       //  Subroutine: evaluate Get opcode args
       //**************************************************************
         begsr evalGet;

           select;
             when oprlvl = 1;
               // parse for Get output
               exsr parseOprSrc;

             when oprlvl = *zeros;
               select;
                 when prmFndSrc = 'WRKPATH';
                   prmGetPath = prmWorkPath;
                   linePhase = ExecPhase;

                 when prmFndSrc = 'OUTPATH';
                   prmGetPath = prmOutPath;
                   linePhase = ExecPhase;

                 other;
                   // unexpected operand parse error
                   prmErrCode = 'RDW0031';
                   exsr parseScriptErr;
                   leavesr;
               endsl;

             other;
               // unexpected operand parse error
               prmErrCode = 'RDW0031';
               exsr parseScriptErr;
               leavesr;
           endsl;

         endsr;

       //**************************************************************
       //  Subroutine: evaluate Find opcode args
       //**************************************************************
         begsr evalFind;

           select;
             when oprlvl = 1;
               // parse for Find source
               exsr parseOprSrc;

             when oprlvl = *zeros;
               // parse for operand compare string
               exsr parseOprCmp;
               if readState = ExitState;
                 leavesr;
               endif;
               linePhase = ExecPhase;
               prmFndState = ResultPhase;

             other;
               // unexpected operand parse error
               prmErrCode = 'RDW0031';
               exsr parseScriptErr;
               leavesr;
           endsl;

         endsr;

       //**************************************************************
       //  Subroutine: execute Find opcode
       //     in:        cmpData      = cmpidx chars to compare
       //                prmFndSrc    = data source to compare
       //                wrkidx       = current position of workfile
       //    out:        cmpFound     = *on if found
       //**************************************************************
         begsr execFind;

           cmpFound = *off;
           mchidx = 1;
           select;
             when prmFndSrc = 'WRKPATH';
               dow prmFndState = ResultPhase;
                 dow wrkidx <= wrklen;
                   if cmpary(mchidx) =
                      %xlate(rdwLower: rdwUpper: wrkary(wrkidx));
                     wrkidx += 1;
                     if mchidx = cmpidx;
                       // found compare string in work file
                       cmpFound = *on;
                       prmFndState = ContinuePhase;
                       leavesr;
                     else;
                       mchidx += 1;
                     endif;
                   else;
                     if mchidx > 1;
                       mchidx = 1;
                     else;
                       wrkidx += 1;
                     endif;
                   endif;
                 enddo;

                 if readState <> ExitState;
                   exsr loadWrkData;
                 endif;
               enddo;

             other;
               // unexpected args parse error
               prmErrCode = 'RDW0035';
               exsr parseScriptErr;
               leavesr;
           endsl;

         endsr;

       //**************************************************************
       //  Subroutine: evaluate SetVar opcode args
       //**************************************************************
         begsr evalSetVar;

           select;
             when oprlvl = 1;
               // parse for SetVar args
               exsr parseOprSrc; // prmFndSrc = SetVar dest
               exsr parseScrVar; // varData = SetVar var

             when oprlvl = *zeros;
               // oprData = SetVar value
               linePhase = ExecPhase;

             other;
               // unexpected operand parse error
               prmErrCode = 'RDW0031';
               exsr parseScriptErr;
               leavesr;
           endsl;

         endsr;

       //**************************************************************
       //  Subroutine: execute SetVar opcode
       //**************************************************************
         begsr execSetVar;

         select;
           when prmFndSrc = 'FORM';

             setFormIdx += 1;
             if setFormIdx > rdwFormMax;
               isError = *on;
               // max script call level exceeded
               prmErrCode = 'RDW0016';
               return isError;
             endif;

             setFormAry(setFormIdx) = varData;
             setFormVal(setFormIdx) = oprData;

           other;
             // unexpected operand parse error
             prmErrCode = 'RDW0031';
             exsr parseScriptErr;
             leavesr;
         endsl;

         endsr;

       //**************************************************************
       //  Subroutine: evaluate Post opcode args
       //**************************************************************
         begsr evalPost;

           select;
             when oprlvl = 1;
               // parse for Post output
               exsr parseOprSrc;

             when oprlvl = *zeros;
               select;
                 when prmFndSrc = 'WRKPATH';
                   prmGetPath = prmWorkPath;
                   linePhase = ExecPhase;

                 when prmFndSrc = 'OUTPATH';
                   prmGetPath = prmOutPath;
                   linePhase = ExecPhase;

                 other;
                   // unexpected operand parse error
                   prmErrCode = 'RDW0031';
                   exsr parseScriptErr;
                   leavesr;
               endsl;

             other;
               // unexpected operand parse error
               prmErrCode = 'RDW0031';
               exsr parseScriptErr;
               leavesr;
           endsl;

         endsr;

       //**************************************************************
       //  Subroutine: parse for operand source
       //**************************************************************
         begsr parseOprSrc;

           fldData = *blanks;
           fldidx = *zeros;
           prmFndSrc = *blanks;
           linePhase = SourcePhase;
           dow linePhase = SourcePhase
             and readState <> ExitState;
             dow scridx <= scrlen;
               evalchar = scrary(scridx);
               select;
                 when evalchar <= nonbrkBlank
                   or evalchar = Colon;
                   linePhase = OperandPhase;
                   leave;
                 other;
                   if fldidx < fldlen;
                     fldidx += 1;
                     fldary(fldidx) = evalchar;
                     scridx += 1;
                     charpos += 1;
                   else;
                     // field exceeds rdwField length parse error
                     prmErrCode = 'RDW0021';
                     exsr parseScriptErr;
                     leavesr;
                   endif;
               endsl;
             enddo;

             if linePhase = SourcePhase;
               exsr loadScrData;
             endif;
           enddo;

           if readState = ExitState;
             leavesr;
           endif;

           fldUpped = %xlate(rdwLower: rdwUpper: fldData);
           prmFndSrc = %trimr(fldUpped);

           // parse for opr colon separator
           exsr parseOprColon;

         endsr;

       //**************************************************************
       //  Subroutine: parse for operand colon separator
       //**************************************************************
         begsr parseOprColon;

           dow readState = SeekOperand;
             dow scridx <= scrlen;
               evalchar = scrary(scridx);
               select;
                 when evalchar <= nonbrkBlank;
                   scridx += 1;
                   charpos += 1;
                 when evalchar = Colon;
                   scridx += 1;
                   charpos += 1;
                   leavesr;
                 other;
                   // unexpected operand parse error
                   prmErrCode = 'RDW0031';
                   exsr parseScriptErr;
                   leavesr;
               endsl;
             enddo;

             if readState = SeekOperand;
               exsr loadScrData;
             endif;
           enddo;

         endsr;

       //**************************************************************
       //  Subroutine: parse for operand compare string
       //**************************************************************
         begsr parseOprCmp;

           cmpData = *blanks;
           cmpidx = *zeros;
           mchidx = 1;

           dow mchidx <= opridx;
             evalchar = oprary(mchidx);
             if cmpidx < cmplen;
               cmpidx += 1;
               cmpary(cmpidx) = %xlate(rdwLower: rdwUpper: evalchar)        ;
               mchidx += 1;
             else;
               // field exceeds rdwField length parse error
               prmErrCode = 'RDW0021';
               exsr parseScriptErr;
               leavesr;
             endif;
           enddo;

         endsr;

       //**************************************************************
       //  Subroutine: parse for script var string
       //**************************************************************
         begsr parseScrVar;

           varData = *blanks;
           varidx = *zeros;

           dow readState = SeekOperand;
             dow scridx <= scrlen;
               evalchar = scrary(scridx);
               select;
                 when linePhase = OperandPhase;
                   select;
                     when evalchar = Quote;
                       linePhase = StringPhase;
                       scridx += 1;
                       charpos += 1;

                     when evalchar <= nonbrkBlank;
                       scridx += 1;
                       charpos += 1;

                     other;
                       // unexpected operand parse error
                       prmErrCode = 'RDW0031';
                       exsr parseScriptErr;
                       leavesr;
                   endsl;

                 when linePhase = StringPhase;
                   select;
                     when evalchar = Quote;
                       linePhase = OperandPhase;
                       scridx += 1;
                       charpos += 1;
                       // parse for colon separator
                       exsr parseOprColon;
                       leavesr;

                     when evalchar < Blank;
                       // unexpected operand parse error
                       prmErrCode = 'RDW0031';
                       exsr parseScriptErr;
                       leavesr;

                     other;
                       if varidx < varlen;
                         varidx += 1;
                         varary(varidx) = evalchar;
                         scridx += 1;
                         charpos += 1;
                       else;
                         // field exceeds rdwField length parse error
                         prmErrCode = 'RDW0021';
                         exsr parseScriptErr;
                         leavesr;
                       endif;
                   endsl;
               endsl;
             enddo;

             if readState = SeekOperand;
               exsr loadScrData;
             endif;
           enddo;

         endsr;

       //**************************************************************
       //  Subroutine: qualify char for field add
       //**************************************************************
         begsr chkFieldAdd;

           charAdded = *off;

           if (%scan(evalchar: rdwLower) > *zeros)
             or (%scan(evalchar: rdwUpper) > *zeros)
             or (%scan(evalchar: rdwNumbers) > *zeros)
             or evalchar = Underline;
             // add text to fld array
             if fldidx < fldlen;
               fldidx += 1;
               fldary(fldidx) = evalchar;
               scridx += 1;
               charpos += 1;
               charAdded = *on;
             else;
               // field exceeds rdwField length parse error
               prmErrCode = 'RDW0021';
               exsr parseScriptErr;
             endif;
           endif;

         endsr;

       //**************************************************************
       //  Subroutine: qualify char for function
       //**************************************************************
         begsr chkFuncAdd;

           charAdded = *off;

           if (%scan(evalchar: rdwLower) > *zeros)
             or (%scan(evalchar: rdwUpper) > *zeros)
             or (%scan(evalchar: rdwNumbers) > *zeros)
             or evalchar = Underline
             or evalchar = Colon
             or evalchar = LeftParen
             or evalchar = RightParen;
             // add text to fnc array
             if fncidx < fnclen;
               fncidx += 1;
               fncary(fncidx) = evalchar;
               charAdded = *on;
             else;
               // field exceeds rdwField length parse error
               prmErrCode = 'RDW0021';
               exsr parseScriptErr;
             endif;
           endif;

         endsr;

       //**************************************************************
       //  Subroutine: add char to string
       //**************************************************************
         begsr chkStringAdd;

           charAdded = *off;

           // add char to string array
           if stridx < strlen;
             stridx += 1;
             strary(stridx) = scrary(scridx);
             scridx += 1;
             charpos += 1;
             charAdded = *on;
           else;
             // field exceeds rdwOperand length parse error
             prmErrCode = 'RDW0032';
             exsr parseScriptErr;
           endif;

         endsr;

       //**************************************************************
       //  Subroutine: add char to args
       //**************************************************************
         begsr chkArgsAdd;

           charAdded = *off;

           // add char to args array
           if argidx < arglen;
             argidx += 1;
             argary(argidx) = scrary(scridx);
             scridx += 1;
             charpos += 1;
             charAdded = *on;
           else;
             // field exceeds rdwOperand length parse error
             prmErrCode = 'RDW0032';
             exsr parseScriptErr;
           endif;

         endsr;

       //**************************************************************
       //  Subroutine: load next Script buffer
       //**************************************************************
         begsr loadScrData;

           select;
             when scrEOF = *on;
               // no more data - check for error and leave
               if linePhase > OpcodePhase;
                 // unexpected EOF parse error
                 prmErrCode = 'RDW0022';
                 exsr parseScriptErr;
               else;
                 readState = ExitState;
               endif;

             other;
               readlen = rdwReadIFS(prmScriptHnd: readPtr: requestLen);
               if readlen < requestLen;
                 scrEOF = *on;
               endif;
               scrlen = readlen;
               scridx = 1;
           endsl;

         endsr;

       //**************************************************************
       //  Subroutine: parse white space to EOL
       //**************************************************************
         begsr parseWhite;

           dow readState = SeekWhite;
             dow scridx <= scrlen;
               evalchar = scrary(scridx);
               select;
                 when evalchar = rdwCR
                   or evalchar = rdwLF
                   or evalchar = Slash;
                   readState = SeekEOL;
                   linePhase = EOLPhase;
                   leavesr;

                 when evalchar <= nonbrkBlank;
                   scridx += 1;
                   charpos += 1;

                 other;
                   // unexpected special character parse error
                   prmErrCode = 'RDW0020';
                   exsr parseScriptErr;
                   leavesr;
               endsl;
             enddo;

             if readState <> ExitState;
               exsr loadScrData;
             endif;
           enddo;

         endsr;

       //**************************************************************
       //  Subroutine: parse to EOL
       //**************************************************************
         begsr parseEOL;

           dow readState = SeekEOL;
             dow scridx <= scrlen;
               evalchar = scrary(scridx);
               select;
                 when evalchar = rdwCR
                   or evalchar = rdwLF;
                   readState = SeekOpcode;
                   linePhase = StartPhase;
                   leavesr;

                 other;
                   scridx += 1;
                   charpos += 1;
               endsl;
             enddo;

             if readState <> ExitState;
               exsr loadScrData;
             endif;
           enddo;

         endsr;

       //**************************************************************
       //  Subroutine: parse CRLF's
       //**************************************************************
         begsr parseCRLF;

           dow readState <> ExitState;
             dow scridx <= scrlen;
               evalchar = scrary(scridx);
               select;
                 when evalchar = rdwCR;
                   scridx += 1;

                 when evalchar = rdwLF;
                   linepos += 1;
                   charpos = *zeros;
                   scridx += 1;

                 other;
                   // have parsed to beginning of line - evaluate
                   leavesr;
               endsl;
             enddo;

             if readState <> ExitState;
               exsr loadScrData;
             endif;
           enddo;

         endsr;

       //**************************************************************
       //  Subroutine: audit parsing error and end script parsing
       //**************************************************************
         begsr parseScriptErr;

           isError = *on;
           prmErrPos = charpos;
           lineErrPos = 'line ' + %char(linepos);

           setRDWvar(prmScript:
                     prmGetUser:
                     'PARSEERR':
                     scrData);

           audParseErr(prmScript:
                       prmErrCode:
                       lineErrPos:
                       prmErrPos);

           readState = ExitState;

         endsr;

       //**************************************************************
       //  Subroutine: open GetPath file
       //**************************************************************
         begsr openGetPath;

           select;
             when prmGetPath = prmWorkPath;
               exsr openWork;

             other;
               // audit work file not found
               prmErrCode = 'RDW0037';
               isError = audScriptErr(prmScript: prmErrCode);
               readState = ExitState;
           endsl;

         endsr;

       //**************************************************************
       //  Subroutine: open wrkPath file
       //**************************************************************
         begsr openWork;

           %str(%addr(WorkPath): (%len(WorkPath)-1)) = %trimr(prmWorkPath);
           WorkHnd = rdwOpenIFS_RO(WorkPath);
           if (WorkHnd < *zeros);
             // audit work file not found
             prmErrCode = 'RDW0037';
             isError = audScriptErr(prmScript: prmErrCode);
             readState = ExitState;
             leavesr;
           endif;

           exsr loadWrkData;

         endsr;

       //**************************************************************
       //  Subroutine: load next Script buffer
       //**************************************************************
         begsr loadWrkData;

           select;
             when wrkEOF = *on;
               wrkRead = *zeros;

             other;
               wrkRead = rdwReadIFS(WorkHnd: wrkPtr: wrkRequest);
               if wrkRead < wrkRequest;
                 wrkEOF = *on;
               endif;
               wrklen = wrkRead;
               wrkidx = 1;
           endsl;

         endsr;

      /end-free
     p parseScript     e

       //**************************************************************
       //  Subprocedure: chkScriptAry
       //  Purpose:      check that script is not already in stack
       //    If this is a nested script call from a stack that has
       //    already invoked this script, there is no namespace
       //    protection from same scriptname collisions. Architecture
       //    could be enhanced to provide nested level namespace,
       //    but workaround is to copy script and name it Script1,
       //    Script2, etc. for lower level calls of the same script.
       //  Parms:        prmScript    = script name
       //                prmErrCode   = error code
       //  Returns:      isError      = *on if script already in stack
       //**************************************************************
       //
     p chkScriptAry    b
     d chkScriptAry    pi                  like(boolean)
     d  prmScript                          like(rdwScript) const
     d  prmErrCode                         like(rdwErrCode)

       // local fields
     d isError         s                   like(boolean) inz(*off)
     d x               s                   like(curScript)
     d y               s                   like(curScript)

      /free
         curScript += 1;
         if curScript > maxScript;
           isError = *on;
           // max script call level exceeded
           prmErrCode = 'RDW0016';
           return isError;
         endif;

         x = curScript-1;
         for y = x downto 1;
           if scriptary(y) = prmScript;
             isError = *on;
             // script name already in call stack
             prmErrCode = 'RDW0017';
             return isError;
           endif;
         endfor;

         scriptary(curScript) = prmScript;
         return isError;

      /end-free
     p chkScriptAry    e

       //**************************************************************
       //  Subprocedure: rmvScriptAry
       //  Purpose:      pop script from stack
       //  Parms:        prmScript    = script name
       //**************************************************************
       //
     p rmvScriptAry    b
     d rmvScriptAry    pi
     d  prmScript                          like(rdwScript) const

      /free
         scriptary(curScript) = *blanks;
         curScript -= 1;

      /end-free
     p rmvScriptAry    e
