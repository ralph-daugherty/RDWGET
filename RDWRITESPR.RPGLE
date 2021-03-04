      *****************************************************************
      *               RDWRITES Prototype Definitions
      *
      *  Copy file RDWRITESPR
      *****************************************************************

      *****************************************************************
      * Data Structure Declaration
      *****************************************************************
      * system program feedback area
     d psds           sds           429
     d  pgmname                      10a
     d  pgmlib                81     90a
     d  jobname              244    253a
     d  usrname                      10a
     d  jobnbr                        6s 0

      * IBM API error data structure
     d qusec           ds
     d  qusbprv                            like(int32) inz(%size(qusec))        Bytes Provided
     d  qusbavl                            like(int32) inz(0)                   Bytes Available
     d  qusei                         7a                                        Exception Id
     d                                1a                                        Reserved
     d  msgdata                     500a

      *****************************************************************
      * Stand Alone Fields Declaration
      *****************************************************************
      * like prototypes
     d boolean         s               n
     d int32           s             10i 0
     d uint32          s             10u 0
     d basePtr         s               *
     d charval         s              1a
     d charloc         s              5  0

      * like constants
     d isysobj         s             10a
     d rdwJobNbr       s              6a

      * constants
     d rdwNull         c                   const(X'00')
     d rdwCR           c                   const(X'0D')
     d rdwLF           c                   const(X'25')
     d nonbrkBlank     c                   const(X'41')
     d Tick            c                   const(X'7D')
     d Ampersand       c                   const('&')
     d Blank           c                   const(' ')
     d Colon           c                   const(':')
     d rdwEqual        c                   const('=')
     d LeftParen       c                   const('(')
     d Percent         c                   const('%')
     d rdwPlus         c                   const('+')
     d Quote           c                   const('"')
     d RightParen      c                   const(')')
     d Slash           c                   const('/')
     d Star            c                   const('*')
     d Underline       c                   const('_')
     d rdwUpper        c                   const('ABCDEFGHIJKLMNOPQRSTUVWXYZ')
     d rdwLower        c                   const('abcdefghijklmnopqrstuvwxyz')
     d rdwNumbers      c                   const('0123456789')
     d HTMLbreak       c                   const('<br>')
