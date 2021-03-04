      *****************************************************************
      *                      RDWGET Testing
      *
      *  Program TESTCGIGET
      *****************************************************************
     h dftactgrp(*no) actgrp('RDWRITES')
     h bnddir('CGIDEV2':'QC2LE':'QUSAPIBD')
      /copy rdwgetsrc,rdwgeth

      *****************************************************************
      * Prototype Definitions
      *****************************************************************
      /copy rdwgetsrc,cgidev2pr
      /copy rdwgetsrc,rdwritespr
      /copy rdwgetsrc,rdwgetpr

      *****************************************************************
      * *Entry Declaration
      *****************************************************************
     d TESTCGIGET      pr
     d TESTCGIGET      pi

      *****************************************************************
      * Data Structure Declaration
      *****************************************************************

      *****************************************************************
      * Stand Alone Fields Declaration
      *****************************************************************
     d testscript      s                   like(rdwScript)
     d testuser        s                   like(rdwUser)
     d testkey         s                   like(rdwVarKey)
     d testvar         s                   like(rdwVarVal)

      *****************************************************************
      * Mainline
      *****************************************************************
      /free
         setNoDebug(*on); // *on for no diagnostics overhead

        // clear the HTML buffer
         if getHtmlBytesBuffered > 0;
           clrHtmlBuffer();
         endif;

        // get input
         nbrVars = zhbGetInput(savedQueryString:qusec);
         select;
           when nbrVars = *zeros;
             testvar = 'Key parm was not included with request';

           other;
             testscript = zhbGetVar('varscript');
             testuser = zhbGetVar('varuser');
             testkey = zhbGetVar('varkey');
             testvar = getRDWvar(testscript: testuser: testkey);
             if testvar = *blanks;
               testvar = 'setRDWvar has not been called with varkey';
             endif;
         endsl;

         htmlMsgStr = htmlHeader + newline + newline +
                      '<html><body><p>' +
                      %trim(testvar) +
                      '</p></body></html>';

         wrtNoSection(%addr(htmlMsgStr)+2:
                      %len(htmlMsgStr));
         wrtSection('*fini');

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
