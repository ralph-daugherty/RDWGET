# RDWGET
 IBM i RPGLE Scripted Web Retrieval

			RDWGET IBM i Scripted Web Retrieval (legacy http:// support only)
			open source RPG ILE /free code 

   RDWGET is a personal project I wrote for retrieving and posting data from web sites using Scott Klement's HTTPAPI library ( available for download from http://www.scottklement.com/httpapi/ ) Excellent support for HTTPAPI is provided by the FTPAPI - HTTPAPI mailing list you'll find there at time I wrote this.

   I provide no explicit support for https. It's example source code for a script language with parser and execute running on IBM i. It is robust, code complete for what I wrote it for and tested. It would need to be extended for any use.

   The main thing I provided in RDWGET is a script language (RPGscript, why not), parser, and execution to specify pages or files to retrieve, positioning on the page, scraping text between two markers, etc. Also provided is syntax for setting form variables to post to a site. Four test scripts are included with the RDWGET source code. A snippet flavor of it:

     get (wrkpath: "HTTP://www.rdwrites.com/iseries/testcgiget?varscript=" + %rdwscript + "&varuser=" + %rdwuser + "&varkey=TESTINP1") 
     find (wrkpath: "<html><body>")
     eval &TESTOUT1 = %rdwsubst(wrkpath: "<p>": "</p>")  //set var value to text between two finds

as part of an example of scraping text from the page, or

     // post
     setvar (form: "message": "Test post from IBM i RDWGET")
     setvar (form: "mode": "reply")
     setvar (form: "sid": &SID)
     setvar (form: "t": "4180")
     setvar (form: "post": "Submit")
     post (wrkpath: "posting.php")

as part of a script to login, post, and logout of a site.

   A configuration file provides locations for input and output among other things for each script. RDWGET is all subprocedures (except a small main entry in the RDWGET program) with two service programs (in addition to that invoked by HTTPAPI calls) and supports including scripts from within scripts if desired.

regards,
Ralph Daugherty
ralph@ee.net
