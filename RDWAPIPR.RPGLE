      *****************************************************************
      *               RDWGET iSeries Scripted Web Retrieval
      *
      *  Copy file RDWAPIPR
      *****************************************************************

      *****************************************************************
       // API prototypes
      *****************************************************************
      * Prototype: RtvJobI
      *****************************************************************
     d RtvJobI         pr                  extpgm('QUSRJOBI')
     d  RcvVar                        1a   options(*varsize)
     d  LenRcvVar                          like(int32) const
     d  RcvVarFmt                     8a   const
     d  JobName                      26a   const
     d  IntJobID                     16a   const
     d  Qusec                              likeds(qusec) options(*nopass)
     d  Reset                         1a   const options(*nopass)

      *****************************************************************
       // RDWAPISV prototypes
      *****************************************************************
      * Subprocedure: rdwCmd
      *****************************************************************
     d rdwCmd          pr                  like(boolean)
     d  prmCmd                     1024    const

      *****************************************************************
      * Subprocedure: rdwJobUser
      *****************************************************************
     d rdwJobUser      pr                  like(isysobj)

      *****************************************************************
      * Subprocedure: rdwJobName
      *****************************************************************
     d rdwJobName      pr
     d  prmJob                             like(isysobj)
     d  prmUser                            like(isysobj)
     d  prmNbr                             like(rdwJobNbr)

      *****************************************************************
      * Data Structure Declaration
      *****************************************************************

      *****************************************************************
      * Stand Alone Fields Declaration
      *****************************************************************
