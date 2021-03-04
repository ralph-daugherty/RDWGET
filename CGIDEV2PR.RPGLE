      *****************************************************************
      *               CGIDEV2 Prototype Definitions
      *
      *  Copy file CGIDEV2PR
      *****************************************************************
      * D specs
      /copy cgidev2/qrpglesrc,prototypeb

      * indicators for getHtmlIfsMult subprocedure
     d IfsMultIndicators...
     d                 ds
     d  NoErrors                           like(boolean)
     d  NameTooLong                        like(boolean)
     d  NotAccessible                      like(boolean)
     d  NoFilesUsable                      like(boolean)
     d  DupSections                        like(boolean)
     d  FileIsEmpty                        like(boolean)

      *****************************************************************
      * Stand Alone Fields Declaration
      *****************************************************************

      * program timing variable
     d sec             s             15p 6

      * number of variables
     d nbrVars         s                   like(int32)

      * string variables
     d htmlMsgStr      s           1000a   varying

     d savedQueryString...
     d                 s          32767a   varying

      * constants
     d newline         c                   const(X'15')

     d CGIDev2Lib      c                   'CGIDEV2'
     d CGIDev2Html     c                   '/CgidevExtHtml/'
     d htmlHeader      c                   'Content-type: text/html'
     d htmlErrMsg      c                    '<html><body> -
     d                                      <p>An error occurred. -
     d                                      Programmer has been notified. -
     d                                      Please try again later. -
     d                                      </p></body></html>'
