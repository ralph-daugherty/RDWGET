      *****************************************************************
      *               RDWGET iSeries Scripted Web Retrieval
      *
      *  Copy file RDWGETPR
      *****************************************************************

      *****************************************************************
      * Prototype: rdwRtvMsgi
      *****************************************************************
     d rdwRtvMsgi      pr                  extpgm('RDWRTVMSGI')
     d  msgf                               like(isysobj) const
     d  msgid                              like(rdwErrCode) const
     d  msgdta                             like(rdwMsgDta) const
     d  msgret                             like(rdwMsgRet)

      *****************************************************************
      * Subprocedure: setRDWvar
      *****************************************************************
     d setRDWvar       pr                  like(boolean)
     d  prmScript                          like(rdwScript) const
     d  prmUser                            like(rdwUser) const
     d  prmKey                             like(rdwVarKey) const
     d  prmValue                           like(rdwVarVal) const

      *****************************************************************
      * Subprocedure: getRDWvar
      *****************************************************************
     d getRDWvar       pr                  like(rdwVarVal)
     d  prmScript                          like(rdwScript) const
     d  prmUser                            like(rdwUser) const
     d  prmKey                             like(rdwVarKey) const

      *****************************************************************
      * Subprocedure: rdwBldPath
      *****************************************************************
     d rdwBldPath      pr                  like(boolean)
     d  prmPath                            like(rdwPath) const
     d  prmSubDir                          like(rdwSubDir) const
     d  prmFile                            like(rdwFile) const
     d  prmScript                          like(rdwScript) const
     d  prmGetUser                         like(rdwUser) const
     d  prmEvalled                         like(rdwPath)
     d  prmErrPos                          like(charloc)

      *****************************************************************
      * Subprocedure: rdwEvalPath
      *****************************************************************
     d rdwEvalPath     pr                  like(boolean)
     d  prmEval                            like(rdwPath) const
     d  prmScript                          like(rdwScript) const
     d  prmGetUser                         like(rdwUser) const
     d  prmEvalled                         like(rdwPath)
     d  prmErrPos                          like(charloc)

      *****************************************************************
      * Subprocedure: rdwGetURL
      *****************************************************************
     d rdwGetURL       pr                  like(boolean)
     d  prmScript                          like(rdwScript) const
     d  prmGetUser                         like(rdwUser) const
     d  prmWorkPath                        like(rdwPath) const
     d  prmOprData                         like(rdwOperand) const

      *****************************************************************
      * Subprocedure: rdwPostURL
      *****************************************************************
     d rdwPostURL      pr                  like(boolean)
     d  prmScript                          like(rdwScript) const
     d  prmGetUser                         like(rdwUser) const
     d  prmWorkPath                        like(rdwPath) const
     d  prmSetFormAry                      like(rdwCmpBuf) const
     d                                     dim(rdwFormMax)
     d  prmSetFormVal                      like(rdwPath) const
     d                                     dim(rdwFormMax)
     d  prmSetFormIdx                      like(rdwState) const
     d  prmOprData                         like(rdwOperand) const

      *****************************************************************
      * Subprocedure: audParseErr
      *****************************************************************
     d audParseErr     pr                  like(boolean)
     d  prmScript                          like(rdwScript) const
     d  prmErrCode                         like(rdwErrCode) const
     d  prmErrLine                         like(isysobj) const
     d  prmErrPos                          like(charloc) const

      *****************************************************************
      * Subprocedure: audScript
      *****************************************************************
     d audScript       pr
     d  prmScript                          like(rdwScript) const
     d  prmMsgCode                         like(rdwErrCode) const

      *****************************************************************
      * Subprocedure: audScriptErr
      *****************************************************************
     d audScriptErr    pr                  like(boolean)
     d  prmScript                          like(rdwScript) const
     d  prmErrCode                         like(rdwErrCode) const

      *****************************************************************
      * Subprocedure: auditScript
      *****************************************************************
     d auditScript     pr
     d  prmScript                          like(rdwScript) const
     d  prmCode                            like(rdwErrCode) const
     d  prmMsg                             like(rdwAudMsg) const

      *****************************************************************
      * Subprocedure: rdwGetTran
      *****************************************************************
     d rdwGetTran      pr                  like(rdwTrnNbr)
     d  keyTran                            like(rdwTrnKey) const

      *****************************************************************
      * Subprocedure: rdwOpenIFS_RO
      *****************************************************************
     d rdwOpenIFS_RO   pr                  like(int32)
     d  prmPathNul                         like(rdwWrkPath) const

      *****************************************************************
      * Subprocedure: rdwReadIFS
      *****************************************************************
     d rdwReadIFS      pr                  like(int32)
     d  prmFileHnd                         like(int32) const
     d  prmBufPtr                          like(basePtr) const
     d  prmRequest                         like(uint32) const

      *****************************************************************
      * Subprocedure: rdwCloseIFS
      *****************************************************************
     d rdwCloseIFS     pr                  like(int32)
     d  prmFileHnd                         like(int32) const

      *****************************************************************
      * Data Structure Declaration
      *****************************************************************

      *****************************************************************
      * Stand Alone Fields Declaration
      *****************************************************************
     d rdwScript       s             10a
     d rdwUser         s             14a
     d rdwVarKey       s              8a
     d rdwVarVal       s           1024a
     d rdwPath         s            120a
     d rdwSubdir       s             40a
     d rdwFile         s             40a
     d rdwMsgDta       s             32a
     d rdwMsgRet       s            132a
     d rdwAudMsg       s            256a
     d rdwTrnKey       s             10a
     d rdwTrnNbr       s              9  0
     d rdwState        s              3  0
     d rdwErrCode      s              7a
     d getErrCode      s                   like(int32)
     d getErrMsg       s             52a
     d nullPath        s             +1    like(rdwPath)
     d rdwWrkPath      s            121a   varying
     d rdwFileBuf      s           1024a
     d rdwField        s             14a
     d rdwOperand      s           1024a
     d rdwCmpBuf       s             32a

     d* Constants
     d SeekOpcode      c                   const(1)
     d SeekResult      c                   const(2)
     d SeekEqual       c                   const(3)
     d SeekOperand     c                   const(4)
     d SeekWhite       c                   const(6)
     d SeekEOL         c                   const(99)
     d ExitState       c                   const(999)
     d StartPhase      c                   const(1)
     d OpcodePhase     c                   const(2)
     d ResultPhase     c                   const(3)
     d FieldPhase      c                   const(4)
     d EqualityPhase   c                   const(5)
     d OperandPhase    c                   const(6)
     d CommentPhase    c                   const(7)
     d StringPhase     c                   const(8)
     d FuncPhase       c                   const(9)
     d ValuePhase      c                   const(10)
     d ArgsPhase       c                   const(11)
     d SourcePhase     c                   const(12)
     d ExecPhase       c                   const(13)
     d WhitePhase      c                   const(14)
     d ContinuePhase   c                   const(98)
     d EOLPhase        c                   const(99)
     d rdwFormMax      c                   const(99)
     d getSUCCESS      c                   const(1)
     d msgFile         c                   'RDWMSGF'

