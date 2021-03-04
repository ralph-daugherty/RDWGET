      *****************************************************************
      *               RDWGET iSeries Scripted Web Retrieval
      *
      *  Service Program RDWAPISV
      *****************************************************************
     h  nomain
      /copy rdwgetsrc,rdwgeth

      *****************************************************************
      * Prototype Definitions
      *****************************************************************
      /copy rdwgetsrc,rdwritespr
      /copy rdwgetsrc,rdwapipr
      /copy qsysinc/qrpglesrc,qusrjobi

       //**************************************************************
       //  Subprocedure: rdwCmd
       //  Purpose:      execute passed CL command
       //  Parms:        prmCmd       = CL command string
       //  Returns:      isError      = *on if error
       //**************************************************************
       //
     p rdwCmd          b                   export
     d rdwCmd          pi                  like(boolean)
     d  prmCmd                     1024a   const

     d qcmdexc         pr                  extpgm('QCMDEXC')
     d  prmCmd                     1024a   const
     d  prmLen                       15p 5 const

       // local fields
     d isError         s                   like(boolean) inz(*off)

      /free
         monitor;
           qcmdexc(%subst(prmCmd:1:%len(prmCmd)):%len(prmCmd));
         on-error;
           isError = *on;
         endmon;

         return isError;

      /end-free
     p rdwCmd          e

       //**************************************************************
       //  Subprocedure: rdwJobUser
       //  Purpose:      retrieve job user with QUSRJOBI API
       //  Returns:      prmUser      = Job user
       //**************************************************************
       //
     p rdwJobUser      b                   export
     d rdwJobUser      pi                  like(isysobj)

       // local fields
     d  prmJob         s                   like(isysobj)
     d  prmUser        s                   like(isysobj)
     d  prmJobNbr      s                   like(rdwJobNbr)

      /free
         rdwJobName(prmJob:
                    prmUser:
                    prmJobNbr);

         return prmUser;

      /end-free
     p rdwJobUser      e

       //**************************************************************
       //  Subprocedure: rdwJobName
       //  Purpose:      retrieve job name with QUSRJOBI API
       //  Parms:        prmJob       = Job name
       //                prmUser      = Job user
       //                prmNbr       = Job number
       //**************************************************************
       //
     p rdwJobName      b                   export
     d rdwJobName      pi
     d  prmJob                             like(isysobj)
     d  prmUser                            like(isysobj)
     d  prmNbr                             like(rdwJobNbr)

      /free
         qusbprv = *zeros;

         RtvJobI(QUSI030000:
                 %size(QUSI030000):
                 'JOBI0300':
                 '*':
                 ' ':
                 qusec);

         prmJob = qusjn04;
         prmUser = qusun04;
         prmNbr = qusjnbr04;

      /end-free
     p rdwJobName      e

