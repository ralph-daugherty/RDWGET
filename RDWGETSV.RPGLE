      *****************************************************************
      *               RDWGET iSeries Scripted Web Retrieval
      *
      *  Service Program RDWGETSV
      *****************************************************************
     h  nomain
      /copy rdwgetsrc,rdwgeth
     h bnddir('HTTPAPI')

      *****************************************************************
      * File Specifications
      *****************************************************************
     frdwgetvar uf a e           k disk    usropn
     frdwgettrn uf a e           k disk    usropn
     frdwgetaud o    e             disk    usropn

      *****************************************************************
      * Prototype Definitions
      *****************************************************************
      /copy rdwgetsrc,rdwritespr
      /copy rdwgetsrc,rdwgetpr
      /copy rdwgetsrc,rdwapipr
      /define webforms
      /copy libhttp/qrpglesrc,httpapi_h
      /copy libhttp/qrpglesrc,ifsio_h

       //**************************************************************
       //  Subprocedure: setRDWvar
       //  Purpose:      sets var value to parm by parm key
       //                adds var if not exist
       //  Parms:        prmScript    = script
       //                prmUser      = script user
       //                prmKey       = var key
       //                prmValue     = var value
       //  Returns:      iserror      = *on if error
       //**************************************************************
       //
     p setRDWvar       b                   export
     d setRDWvar       pi              n
     d  prmScript                          like(varscr) const
     d  prmUser                            like(varuser) const
     d  prmKey                             like(varkey) const
     d  prmValue                           like(varval) const

       // local fields
     d isError         s                   like(boolean)

      /free
         isError = *on;

         open(e) rdwgetvar;
         if %error;
           return isError;
         endif;

         chain(e) (prmScript: prmUser: prmKey) rdwgetvar;
         if %error;
           return isError;
         endif;

         varval = prmValue;
         if %found(rdwgetvar);
           update(e) getvarr;
           if %error;
             return isError;
           endif;
         else;
           varscr = prmScript;
           varuser = prmUser;
           varkey = prmKey;
           write(e) getvarr;
           if %error;
             return isError;
           endif;
         endif;

         close(e) rdwgetvar;
         isError = *off;
         return isError;

      /end-free
     p setRDWvar       e

       //**************************************************************
       //  Subprocedure: getRDWvar
       //  Purpose:      gets var value by parm key
       //  Parms:        prmScript    = script
       //                prmUser      = script user
       //                prmKey       = var key
       //  Returns:      prmValue     = var value
       //**************************************************************
       //
     p getRDWvar       b                   export
     d getRDWvar       pi                  like(varval)
     d  prmScript                          like(varscr) const
     d  prmUser                            like(varuser) const
     d  prmKey                             like(varkey) const

       // local fields
     d prmValue        s                   like(varval)

      /free
         prmValue = *blanks;

         open(e) rdwgetvar;
         if %error;
           return prmValue;
         endif;

         chain(ne) (prmScript: prmUser: prmKey) rdwgetvar;
         if %found(rdwgetvar);
           prmValue = varval;
         endif;

         close(e) rdwgetvar;
         return prmValue;

      /end-free
     p getRDWvar       e

       //**************************************************************
       //  Subprocedure: rdwBldPath
       //  Purpose:      build null terminated path from standard path,
       //    optional subdirectory, and optional filename.
       //  Parms:        prmPath      = directory path
       //                prmSubdir    = optional subdirectory path
       //                prmFile      = optional file name
       //                prmScript    = script name
       //                prmGetUser   = getvar user
       //                prmEvalled   = optionally substituted path value
       //                prmErrPos    = char position of error
       //  Returns:      isError      = *on if error
       //**************************************************************
       //
     p rdwBldPath      b                   export
     d rdwBldPath      pi                  like(boolean)
     d  prmPath                            like(rdwPath) const
     d  prmSubDir                          like(rdwSubDir) const
     d  prmFile                            like(rdwFile) const
     d  prmScript                          like(rdwScript) const
     d  prmGetUser                         like(rdwUser) const
     d  prmEvalled                         like(rdwPath)
     d  prmErrPos                          like(charloc)

       // local fields
     d isError         s                   like(boolean) inz(*off)
     d wrkPath         s                   like(rdwPath)

      /free
         isError = rdwEvalPath(prmPath:
                               prmScript:
                               prmGetUser:
                               prmEvalled:
                               prmErrPos);

         if isError = *on;
           return IsError;
         endif;

         wrkPath = prmEvalled;

         if prmSubDir <> *blanks;
           isError = rdwEvalPath(prmSubDir:
                                 prmScript:
                                 prmGetUser:
                                 prmEvalled:
                                 prmErrPos);

           if prmEvalled <> *blanks;
             wrkPath = %trimr(wrkPath) + prmEvalled;
           endif;
           if isError = *on;
             prmEvalled = wrkPath;
             return IsError;
           endif;
         endif;

         if prmFile <> *blanks;
           isError = rdwEvalPath(prmFile:
                                 prmScript:
                                 prmGetUser:
                                 prmEvalled:
                                 prmErrPos);

           if prmEvalled <> *blanks;
             wrkPath = %trimr(wrkPath) + prmEvalled;
           endif;
         endif;

         prmEvalled = wrkPath;
         return isError;

      /end-free
     p rdwBldPath      e

       //**************************************************************
       //  Subprocedure: rdwEvalPath
       //  Purpose:      substitute and return trim eval path first blank
       //  Parms:        prmEval      = path to evaluate
       //                prmScript    = script name
       //                prmGetUser   = getVar user
       //                prmEvalled   = optionally substituted path value
       //                prmErrPos    = char position of error
       //  Returns:      isError      = *on if error
       //**************************************************************
       //
     p rdwEvalPath     b                   export
     d rdwEvalPath     pi                  like(boolean)
     d  prmEval                            like(rdwPath) const
     d  prmScript                          like(rdwScript) const
     d  prmGetUser                         like(rdwUser) const
     d  prmEvalled                         like(rdwPath)
     d  prmErrPos                          like(charloc)

       // local fields
     d                 ds
     d  wrkData                            like(prmEval)
     d  wrkary                             like(charval) dim(%size(wrkData))
     d                                     overlay(wrkData: 1)
     d wrklen          s                   like(charloc) inz(%size(wrkData))
     d wrkidx          s                   like(charloc) inz(1)

     d                 ds
     d  outData                            like(prmEval)
     d  outary                             like(charval) dim(%size(outData))
     d                                     overlay(outData: 1)
     d outlen          s                   like(charloc) inz(%size(outData))
     d outidx          s                   like(charloc) inz(*zeros)

     d isError         s                   like(boolean) inz(*off)
     d evalchar        s                   like(charval)

      /free
         wrkData = prmEval;
         dow wrkidx <= wrklen;
           evalchar = wrkary(wrkidx);
           select;
             when evalchar <= nonbrkBlank;
               // end of eval string
               leave;

             other;
               // add text to out array
               if outidx < outlen;
                 outidx += 1;
                 outary(outidx) = wrkary(wrkidx);
                 wrkidx += 1;
               else;
                 prmErrPos = wrkidx;
                 isError = *on;
                 setRDWvar(prmScript:
                           prmGetUser:
                           'PARSEERR':
                           prmEval);
                 leave;
               endif;
           endsl;
         enddo;

         prmEvalled = outData;
         return isError;

      /end-free
     p rdwEvalPath     e

       //**************************************************************
       //  Subprocedure: rdwGetURL
       //  Purpose:      get URL and store to wrkPath file
       //  Parms:        prmScript    = script name
       //                prmGetUser   = getVar user
       //                prmWorkPath  = RDWGET script work path
       //                prmOprData   = URL
       //  Returns:      isError      = *on if error
       //**************************************************************
       //
     p rdwGetURL       b                   export
     d rdwGetURL       pi                  like(boolean)
     d  prmScript                          like(rdwScript) const
     d  prmGetUser                         like(rdwUser) const
     d  prmWorkPath                        like(rdwPath) const
     d  prmOprData                         like(rdwOperand) const

       // local fields
     d isError         s                   like(boolean) inz(*off)
     d url             s                   like(rdwOperand)
     d rc              s                   like(int32)

      /free
         rc = *zeros;
         geterrmsg = *blanks;
         url = prmOprData;

         dou rc <> 302;
           rc = http_url_get(%trimr(url):
                        prmWorkPath);

           if rc = 302;
             url = http_redir_loc;
           endif;
         enddo;

         if rc <> getSUCCESS;
           geterrmsg = http_error;
           auditScript(prmScript:
                       'GETERR':
                       geterrmsg);

           setRDWvar(prmScript:
                     prmGetUser:
                     'GETERR':
                     prmOprData);

           isError = *on;
         endif;

         return isError;

      /end-free
     p rdwGetURL       e

       //**************************************************************
       //  Subprocedure: rdwPostURL
       //  Purpose:      post form to URL and store to wrkPath file
       //  Parms:        prmScript    = script name
       //                prmGetUser   = getVar user
       //                prmWorkPath  = RDWGET script work path
       //                prmSetFormAry= form variables
       //                prmSetFormVal= form variable values
       //                prmSetFormIdx= form variables index
       //                prmOprData   = URL
       //  Returns:      isError      = *on if error
       //**************************************************************
       //
     p rdwPostURL      b                   export
     d rdwPostURL      pi                  like(boolean)
     d  prmScript                          like(rdwScript) const
     d  prmGetUser                         like(rdwUser) const
     d  prmWorkPath                        like(rdwPath) const
     d  prmSetFormAry                      like(rdwCmpBuf) const
     d                                     dim(rdwFormMax)
     d  prmSetFormVal                      like(rdwPath) const
     d                                     dim(rdwFormMax)
     d  prmSetFormIdx                      like(rdwState) const
     d  prmOprData                         like(rdwOperand) const

       // local fields
     d isError         s                   like(boolean) inz(*off)
     d rc              s                   like(int32)
     d Form            s                   like(WEBFORM)
     d FormPtr         s                   like(basePtr)
     d dataSize        s                   like(int32)
     d x               s                   like(prmSetFormIdx)

      /free
         rc = *zeros;
         geterrmsg = *blanks;

         Form = WEBFORM_open;

         for x = 1 to prmSetFormIdx;
           callp WEBFORM_SetVar(Form: %trimr(prmSetFormAry(x)):
                                      %trimr(prmSetFormVal(x)));
         endfor;

         callp WEBFORM_postData(Form: FormPtr: dataSize);

         rc = http_url_post(
                %trimr(prmOprData)
                :FormPtr
                :dataSize
                :prmWorkPath
                :HTTP_TIMEOUT
                :HTTP_USERAGENT
                :'application/x-www-form-urlencoded');

         if rc = 302;
           isError = rdwGetURL(prmScript:
                               prmGetUser:
                               prmWorkPath:
                               http_redir_loc);
         endif;

         callp WEBFORM_close(Form);
         return isError;

      /end-free
     p rdwPostURL      e

       //**************************************************************
       //  Subprocedure: audParseErr
       //  Purpose:      audit error message for parsing
       //                Error message contains loc of error of line.
       //  Parms:        prmScript    = script name
       //                prmErrCode   = error code
       //                prmErrLine   = line position of error
       //                prmErrPos    = char position of error
       //  Returns:      isLR         = *on if fatal error
       //**************************************************************
       //
     p audParseErr     b                   export
     d audParseErr     pi                  like(boolean)
     d  prmScript                          like(rdwScript) const
     d  prmErrCode                         like(rdwErrCode) const
     d  prmErrLine                         like(isysobj) const
     d  prmErrPos                          like(charloc) const

       // local fields
     d isLR            s                   like(boolean)
     d prmMsgDta       s                   like(rdwMsgDta)
     d prmMsgRet       s                   like(rdwMsgRet)
     d prmAudMsg       s                   like(rdwAudMsg)
     d tmpfld          s              2a
     d tmplen          s                   like(charloc)

      /free
         tmplen = %len(%char(prmErrPos));
         select;
           when tmplen = 1;
             tmpfld = X'0002';

           when tmplen = 2;
             tmpfld = X'0003';

           when tmplen = 3;
             tmpfld = X'0004';

           other;
             tmpfld = X'0005';
         endsl;

         prmMsgDta = tmpfld +
                     %char(prmErrPos) +
                     Blank +
                     (X'000A') +
                     (%trimr(prmErrLine));
         callp rdwRtvMsgi(msgFile: prmErrCode: prmMsgDta: prmMsgRet);
         prmAudMsg = prmMsgRet;
         auditScript(prmScript:
                     prmErrCode:
                     prmAudMsg);
         isLR = *on;
         return isLR;

      /end-free
     p audParseErr     e

       //**************************************************************
       //  Subprocedure: audScript
       //  Purpose:      audit message for script.
       //                Message contains parm for script name.
       //  Parms:        prmScript    = script name
       //                prmMsgCode   = message code
       //**************************************************************
       //
     p audScript       b                   export
     d audScript       pi
     d  prmScript                          like(rdwScript) const
     d  prmMsgCode                         like(rdwErrCode) const

       // local fields
     d prmMsgRet       s                   like(rdwMsgRet)
     d prmAudMsg       s                   like(rdwAudMsg)

      /free
         callp rdwRtvMsgi(msgFile: prmMsgCode: prmScript: prmMsgRet);
         prmAudMsg = prmMsgRet;
         auditScript(prmScript:
                     prmMsgCode:
                     prmAudMsg);

      /end-free
     p audScript       e

       //**************************************************************
       //  Subprocedure: audScriptErr
       //  Purpose:      audit error message for script.
       //                Error message contains parm for script name.
       //  Parms:        prmScript    = script name
       //                prmErrCode   = error code
       //  Returns:      isLR         = *on if fatal error
       //**************************************************************
       //
     p audScriptErr    b                   export
     d audScriptErr    pi                  like(boolean)
     d  prmScript                          like(rdwScript) const
     d  prmErrCode                         like(rdwErrCode) const

       // local fields
     d isLR            s                   like(boolean)
     d prmMsgRet       s                   like(rdwMsgRet)
     d prmAudMsg       s                   like(rdwAudMsg)

      /free
         callp rdwRtvMsgi(msgFile: prmErrCode: prmScript: prmMsgRet);
         prmAudMsg = prmMsgRet;
         auditScript(prmScript:
                     prmErrCode:
                     prmAudMsg);
         isLR = *on;
         return isLR;

      /end-free
     p audScriptErr    e

       //**************************************************************
       //  Subprocedure: auditScript
       //  Purpose:      audit file for Script processing messages.
       //                Errors at any level or completion of top level script.
       //  Parms:        prmKey       = RDWGET script key
       //                prmCode      = audit code
       //                prmMsg       = audit message
       //**************************************************************
       //
     p auditScript     b                   export
     d auditScript     pi
     d  prmKey                             like(rdwScript) const
     d  prmCode                            like(rdwErrCode) const
     d  prmMsg                             like(rdwAudMsg) const

       // local fields
     d prmFile         c                   'RDWGETAUD'

      /free
         open(e) rdwgetaud;
         if %error;
           return;
         endif;

         audtrn = rdwGetTran(prmFile);
         audkey = prmKey;
         rdwJobName(audjob:
                    auduser:
                    audjobnbr);
         audstmp = %timestamp();
         audcode = prmCode;
         audmsg = prmMsg;

         write(e) getaudr;
         close(e) rdwgetaud;

      /end-free
     p auditScript     e

       //**************************************************************
       //  Subprocedure: rdwGetTran
       //  Purpose:      get next tran number from tran control file by key
       //  Parms:        prmFile      = RDWGET file tran key
       //  Returns:      prmTrn       = tran number
       //**************************************************************
       //
     p rdwgetTran      b                   export
     d rdwgetTran      pi                  like(rdwTrnnbr)
     d  prmFile                            like(rdwTrnkey) const

       // local fields
     d prmTrn          s                   like(rdwTrnNbr)

      /free
         prmTrn = *zeros;

         open(e) rdwgettrn;
         if %error;
           return prmTrn;
         endif;

         chain(e) (prmFile) rdwgettrn;
         if not %found(rdwgettrn);
           // create tran key
           trnkey = prmFile;
           trnnbr = 1;
           write(e) gettrnr;
           if not %error;
             prmTrn = trnnbr;
           endif;
         else;
           // inc tran key
           monitor;
             trnnbr += 1;
           on-error;
             trnnbr = 1;
           endmon;
           update(e) gettrnr;
           if not %error;
             prmTrn = trnnbr;
           endif;
         endif;

         close(e) rdwgettrn;
         return prmTrn;

      /end-free
     p rdwGetTran      e

       //**************************************************************
       //  Subprocedure: rdwOpenIFS_RO
       //  Purpose:      procedure to open IFS file read only
       //  Parms:        prmPathNul   = null terminated path ptr
       //  Returns:      prmFileHnd   = file handle
       //**************************************************************
       //
     p rdwOpenIFS_RO   b                   export
     d rdwOpenIFS_RO   pi                  like(int32)
     d  prmPathNul                         like(rdwWrkPath) const

      /free

         return open(prmPathNul: O_RDONLY + O_TEXTDATA);

      /end-free
     p rdwOpenIFS_RO   e

       //**************************************************************
       //  Subprocedure: rdwReadIFS
       //  Purpose:      procedure to read IFS file
       //  Parms:        prmFileHnd   = file handle
       //                prmBufPtr    = read buffer ptr
       //                prmRequest   = requested read length
       //  Returns:      prmRead      = read length
       //**************************************************************
       //
     p rdwReadIFS      b                   export
     d rdwReadIFS      pi                  like(int32)
     d  prmFileHnd                         like(int32) const
     d  prmBufPtr                          like(basePtr) const
     d  prmRequest                         like(uint32) const

      /free

         return read(prmFileHnd: prmBufPtr: prmRequest);

      /end-free
     p rdwReadIFS      e

       //**************************************************************
       //  Subprocedure: rdwCloseIFS
       //  Purpose:      procedure to close IFS file
       //  Parms:        prmFileHnd   = file handle
       //  Returns:      status       = int status
       //**************************************************************
       //
     p rdwCloseIFS     b                   export
     d rdwCloseIFS     pi                  like(int32)
     d  prmFileHnd                         like(int32) const

      /free

         return closef(prmFileHnd);

      /end-free
     p rdwCloseIFS     e
