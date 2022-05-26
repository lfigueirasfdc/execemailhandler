@isTest
private class ExecEmailHandlerTest {
      
    static testMethod void testInboundEmailExistingContact() {
    
        String contactName = 'Original Sender';
        String contactEmail = 'original.sender@fakemail.invalid';
        String originalSubject = 'Original Subject';

        Messaging.InboundEmail email = buildFakeEmail(contactName, contactEmail, originalSubject);
        Messaging.InboundEnvelope env = buildEnvelope();

        ExecEmailHandler handler = new ExecEmailHandler();

        Contact fakeContact = new Contact(FirstName = 'Original', LastName = 'Sender', Email = contactEmail);
        insert fakeContact;

        Test.startTest();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, env);
        Test.stopTest();

        List<Case> newCases = [select Id, Subject, ContactId from Case];

        System.assertEquals(true, result.success, 'Failure in inbound email handler function: ' + result.message);
        System.assert(newCases.size()>0, 'Case was not created');
        System.debug('New case: ' + newCases[0]);
        System.assertEquals(fakeContact.Id, newCases[0].ContactId, 'Wrong or no contact associated to Case');
        System.assertEquals(originalSubject, newCases[0].Subject, 'Wrong Case subject');
    }

    static testMethod void testInboundEmailNoContact() {
    
        String contactName = 'Original Sender';
        String contactEmail = 'original.sender@fakemail.invalid';
        String originalSubject = 'Original Subject';

        Messaging.InboundEmail email = buildFakeEmail(contactName, contactEmail, originalSubject);
        Messaging.InboundEnvelope env = buildEnvelope();

        ExecEmailHandler handler = new ExecEmailHandler();

        Test.startTest();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, env);
        Test.stopTest();

        List<Case> newCases = [select Id, Subject, ContactId, SuppliedName, SuppliedEmail from Case];

        System.assertEquals(true, result.success, 'Failure in inbound email handler function: ' + result.message);
        System.assert(newCases.size()>0, 'Case was not created');
        System.debug('New case: ' + newCases[0]);
        System.assertEquals(contactName, newCases[0].SuppliedName, 'Wrong name associated to Case');
        System.assertEquals(contactEmail, newCases[0].SuppliedEmail, 'Wrong name associated to Case');
        System.assert(newCases[0].ContactId == null, 'Contact was incorrectly associated to Case');
        System.assertEquals(originalSubject, newCases[0].Subject, 'Wrong Case subject');
    }

    static testMethod void testException() {
    
        String contactName = 'Original Sender';
        String contactEmail = 'original.sender@invalid';
        String originalSubject = 'Original Subject';

        Messaging.InboundEmail email = buildFakeEmail(contactName, contactEmail, originalSubject);
        Messaging.InboundEnvelope env = buildEnvelope();

        ExecEmailHandler handler = new ExecEmailHandler();

        Test.startTest();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, env);
        Test.stopTest();

        System.assertEquals(false, result.success, 'Exception should have been raised');
    }

    static Messaging.InboundEnvelope buildEnvelope() {

        // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_email_inbound_envelope.htm#apex_classes_email_inbound_envelope

        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        env.fromAddress = 'lfigueira@salesforce.com';
        env.toAddress = 'lfigueira@salesforce.com';

        return env;
    }

    static Messaging.InboundEmail buildFakeEmail(String originalSenderName, String originalSenderEmailAddress, String originalSubject) {

        Messaging.InboundEmail email = new Messaging.InboundEmail();

        email.ccAddresses = new List<String>{'ccaddress1@fakemail.invalid', 'ccaddress2@fakemail.invalid'};
        email.fromAddress = 'fromaddress@fakemail.invalid';
        email.fromName = 'From Contact';
        email.headers = new List<Messaging.InboundEmail.Header>();

        Messaging.InboundEmail.Header fromHeader = new Messaging.InboundEmail.Header(); 
        fromHeader.name = 'From Contact';
        fromHeader.value = 'From Contact <fromaddress@fakemail.invalid>';
        email.headers.add(fromHeader);

        Messaging.InboundEmail.Header dateHeader = new Messaging.InboundEmail.Header(); 
        dateHeader.name = 'Date';
        dateHeader.value = 'Tue, 6 Apr 2021 19:33:43 +0100';
        email.headers.add(dateHeader);

        email.htmlBody = '<!DOCTYPE html><html lang="en"><body><h1>Quod, inquit, quamquam voluptatibus quibusdam est saepe iucundius, tamen expetitur propter voluptatem.</h1><p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Certe non potest. <b>Sed fac ista esse non inportuna;</b> Quam si explicavisset, non tam haesitaret. <a href=\'http://loripsum.net/\' target=\'_blank\'>Bona autem corporis huic sunt, quod posterius posui, similiora.</a> Quarum ambarum rerum cum medicinam pollicetur, luxuriae licentiam pollicetur. </p> <p>Erit enim mecum, si tecum erit. Duo Reges: constructio interrete. At enim hic etiam dolore. <i>Non autem hoc: igitur ne illud quidem.</i> Bonum liberi: misera orbitas. Quid de Pythagora? </p></body></html>';
        email.htmlBodyIsTruncated = false;
        email.plainTextBody = 'Quod, inquit, quamquam voluptatibus quibusdam est saepe iucundius, tamen expetitur propter voluptatem. \n---------- Forwarded message ---------\nFrom: ' + originalSenderName + ' <' + originalSenderEmailAddress + '>\nDate: Fri, 2 Apr 2021 at 10:19\nSubject: ' + originalSubject + '\nTo: From Contact <fromaddress@fakemail.invalid>, Luis Figueira <\nlfigueira@salesforce.com>\n\nLorem ipsum dolor sit amet, consectetur adipiscing elit. Certe non potest. <b>Sed fac ista esse non inportuna; Quam si explicavisset, non tam haesitaret. Bona autem corporis huic sunt, quod posterius posui, similiora. Quarum ambarum rerum cum medicinam pollicetur, luxuriae licentiam pollicetur. \n \n Erit enim mecum, si tecum erit. Duo Reges: constructio interrete. At enim hic etiam dolore. Non autem hoc: igitur ne illud quidem. Bonum liberi: misera orbitas. Quid de Pythagora?';
        email.plainTextBodyIsTruncated = false;
        email.subject = 'Fwd: Original Subject';
        email.textAttachments = null;
        email.toAddresses = new List<String>{'toaddress@fakemail.invalid'};

        return email;
    }

    static Messaging.InboundEmail buildRealEmail() {

        // Create a new email and envelope object.
        // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_email_inbound_inbound.htm#apex_classes_email_inbound_inbound
        // The following are properties for InboundEmail.
        // binaryAttachments
        // A list of binary attachments received with the email, if any.
        // ccAddresses
        // A list of carbon copy (CC) addresses, if any.
        // fromAddress
        // The email address that appears in the From field.
        // fromName
        // The name that appears in the From field, if any.
        // headers
        // A list of the RFC 2822 headers in the email.
        // htmlBody
        // The HTML version of the email, if specified by the sender.
        // htmlBodyIsTruncated
        // Indicates whether the HTML body text is truncated (true) or not (false.)
        // inReplyTo
        // The In-Reply-To field of the incoming email. Identifies the email or emails to which this one is a reply (parent emails). Contains the parent email or emails' message-IDs.
        // messageId
        // The Message-ID—the incoming email's unique identifier.
        // plainTextBody
        // The plain text version of the email, if specified by the sender.
        // plainTextBodyIsTruncated
        // Indicates whether the plain body text is truncated (true) or not (false.)
        // references
        // The References field of the incoming email. Identifies an email thread. Contains a list of the parent emails' References and message IDs, and possibly the In-Reply-To fields.
        // replyTo
        // The email address that appears in the reply-to header.
        // subject
        // The subject line of the email, if any.
        // textAttachments
        // A list of text attachments received with the email, if any.
        // toAddresses
        // The email address that appears in the To field.

        Messaging.InboundEmail email = new Messaging.InboundEmail();

        // email.binaryAttachments
        // A list of binary attachments received with the email, if any.
        email.ccAddresses = new List<String>{'ccaddress1@fakemail.invalid', 'ccaddress2@fakemail.invalid'};
        // A list of carbon copy (CC) addresses, if any.
        email.fromAddress = 'lfigueira@salesforce.com';
        // The email address that appears in the From field.
        email.fromName = 'Luis Figueira';
        // The name that appears in the From field, if any.
        email.headers = new List<Messaging.InboundEmail.Header>();
        // A list of the RFC 2822 headers in the email.

        // Messaging.InboundEmail.Header referencesHeader = new Messaging.InboundEmail.Header(); 
        // referencesHeader.name = 'References';
        // referencesHeader.value = '<CAJJ+yQCnJh3pnJJtuaRcW3GS=B_D5fgnO7P3AQWHcEOJQmbURw@mail.gmail.com>';
        // email.headers.add(referencesHeader);
        
        // Messaging.InboundEmail.Header inReplyToHeader = new Messaging.InboundEmail.Header(); 
        // inReplyToHeader.name = 'In-Reply-To';
        // inReplyToHeader.value = '<CAJJ+yQCnJh3pnJJtuaRcW3GS=B_D5fgnO7P3AQWHcEOJQmbURw@mail.gmail.com>';
        // email.headers.add(inReplyToHeader);

        Messaging.InboundEmail.Header fromHeader = new Messaging.InboundEmail.Header(); 
        fromHeader.name = 'From';
        fromHeader.value = 'Luis Figueira <lfigueira@salesforce.com>';
        email.headers.add(fromHeader);

        Messaging.InboundEmail.Header dateHeader = new Messaging.InboundEmail.Header(); 
        dateHeader.name = 'Date';
        dateHeader.value = 'Tue, 6 Apr 2021 19:33:43 +0100';
        email.headers.add(dateHeader);

        // Messaging.InboundEmail.Header messageIdHeader = new Messaging.InboundEmail.Header(); 
        // messageIdHeader.name = 'Message-ID';
        // messageIdHeader.value = '<CAP14qCAJiWYbJLhK6BWruodpom-zX9CsJVt7LyAcp5BVL9uN9w@mail.gmail.com>';
        // email.headers.add(messageIdHeader);

        email.htmlBody = '<meta http-equiv=3D"Content-Type" content=3D"text/html; charset=3Dutf-8"><d=iv dir=3D"ltr">This needs to create a case for Baig\'s contact and ignore this part of the email.<div><br clear=3D"all"><div><div dir=3D"ltr" class=3D"gmail_signature" data-smartmail=3D"gmail_signature"><div dir=3D"ltr"><div><=div dir=3D"ltr"><div>Luis Figueira</div><div>Senior Program Architect | Salesforce</div><div>Mobile: +44 (0) 7909 610 528</div><div><a href=3D"mailto:lfigueira@salesforce.com" target=3D"_blank">lfigueira@salesforce.com</a><br></div><div><a href=3D"https://urldefense.proofpoint.com/v2/url?u=3Dhttp-3A__www.salesforce.com&amp;d=3DDwMFaQ&amp;c=3D6zrz5v1771esYjKEWYkRSg&amp;r=3Ddt1ePLp4yrbPyNghVm9PsY5YEdPP7uT7Ja9nPkHZI2g&amp;m=3D0Fhr8bpN4ALUXB9jiTyE-fzANUpPVwlD8LFwxNH4W7M&amp;s=3DjTtdWOetvdQIDQpAbT__C6p-DFs5pBNeUqJvekqzB-c&amp;e=3D" target=3D"_blank"><img src=3D"http://www.salesforce.com/common/assets/images/email/salesforce-email-signature.png"> [salesforce.com]</a><br></div></div></div></div></div></div><br><br><div class=3D"gmail_quote"><div dir=3D"ltr" class=3D"gmail_attr">---------- Forwarded message ---------<br>From: <strong class=3D"gmail_sendername" dir=3D"auto">Rahmathulla Baig</strong> <span dir=3D"auto">&lt;<a href=3D"mailto:rahmathulla.baig@mulesoft.com">rahmathulla.baig@mulesoft.com</a>&gt;</span><br>Date: Fri, 2 Apr 2021 at 10:19<br>Subject: Status Today<br>To: Steven Walker &lt;<a href=3D"mailto:steven.walker@CONFIDENTIAL.COM">steven.walker@CONFIDENTIAL.COM</a>&gt;, Luis Figueira &lt;<a href=3D"mailto:lfigueira@salesforce.com">lfigueira@salesforce.com</a>&gt;, Christopher Bozwell &lt;<a href=3D"mailto:Christopher.Bozwell@CONFIDENTIAL.COM">Christopher.Bozwell@CONFIDENTIAL.COM</a>&gt;, Peter Latimer &lt;<a href=3D"mailto:peter.latimer@CONFIDENTIAL.COM">peter.latimer@CONFIDENTIAL.COM</a>&gt;<br>Cc: Mike Jakeman &lt;<a href=3D"mailto:mjakeman@mulesoft.com">mjakeman@mulesoft.com</a>&gt;, Yatish Ghedia &lt;<a href=3D"mailto:yghedia@mulesoft.com">yghedia@mulesoft.com</a>&gt;<br></div><br><br><div dir=3D"ltr">Hi All<div><br></div><div>I have made few changes in the code to avoid some issues in the data coming from Curo.</div><div><br></div><div>1. Tasks, Emails, Notes</div><div>Some objects don\'t have Subject/Title, it comes as an empty string and Salesforce does not like it to be empty. So I\'m defaulting the value to &quot;No Subject&quot; / &quot;No Title&quot; and not failing the client.</div><div><br></div><div>2. Tasks limit 100</div><div>There was a bug introduced&nbsp;by me where I had set a limit of 100 on Tasks and forgot to remove it after my standalone testing. I\'ve fixed this.</div><div><br></div><div>3. Skipping migration steps</div><div>In case there are no Events or Tasks or Emails there is no necessity to invoke participants, notes and attachments flows. So, I skip those nested steps and move to the next entity. With this change, if a Client has NO content at all (which I do get from Curo), now it takes 5 seconds to finish with this client. Earlier it used to unnecessarily&nbsp;spend 30-40 seconds going through the chain.</div><div><br></div><div>Having said that, I have tested 49 clients\' migration and were hit by a road-blocker (&quot;storage limit exceeded&quot;).</div><div><br></div><div>Please find enclosed the list of issues (existing ones and new ones).</div><div><br></div><div>In Summary</div><div>1. We are getting <font face=3D"monospace">&quot;unable to obtain exclusive access to this record&quot;</font> almost everywhere, including tasks, emails, events, recipients. Seems not consistent though, sometimes it passes-through (can\'t say when).</div><div><br></div><div>2. We are getting this on Events <font face=3D"monospace">&quot;We can\'t save this record because the =E2=80=9CEvent - Created - After Save=E2=80=9D</font>&nbsp; in varied forms, please see the description in detail. Looks like some buggy code in Salesforce validation.</div><div><br></div><div>3. New Issue, seems like there is some disk or data limit also on Events <font face=3D"monospace">&quot;storage limit exceeded&quot;</font>. I saw this error today morning after which all clients failed with this error, so I had to stop testing at 49 clients.</div><div><br></div><div>4. HTML body is too long, we anticipated this issue earlier but assumed that the Salesforce column size is high enough to manage it. I hit upon this issue on one of the client\'s Email migrations. So we have to trim the HTML (which is coming in as base64 encoded).</div><div><br></div><div>5. Account not found on Curo</div><div>This problem still exists even after changing to the new query provided by Chris.</div><div><br></div><div>I\'m really not sure if Salesforce has put these restrictions on purpose. It\'s like a can of worms, never ending issues from its side.</div><div><br></div><div>Can we bring in Salesforce Architect to tell us what is wrong with it? Do these business rules also apply for Bulk APIs, which I guess it should, It can\'t be restricted only to Graph&nbsp;APIs. If it\'s&nbsp;only restricted to Graph APIs, I don\'t see a point why would anybody use&nbsp;this API.</div><div><br></div><div><br></div><div>Thanks</div><div>Baig</div><div><br></div><div><br></div><div><br></div><div><br></div></div></div></div></div>';
        // The HTML version of the email, if specified by the sender.
        email.htmlBodyIsTruncated = false;
        // Indicates whether the HTML body text is truncated (true) or not (false.)
        email.inReplyTo = '<CAJJ+yQCnJh3pnJJtuaRcW3GS=B_D5fgnO7P3AQWHcEOJQmbURw@mail.gmail.com>';
        // The In-Reply-To field of the incoming email. Identifies the email or emails to which this one is a reply (parent emails). Contains the parent email or emails' message-IDs.
        email.messageId = '<CAP14qCAJiWYbJLhK6BWruodpom-zX9CsJVt7LyAcp5BVL9uN9w@mail.gmail.com>';
        // The Message-ID—the incoming email's unique identifier.
        email.plainTextBody = '\nThis needs to create a case for Baig\'s contact and ignore this part of the\n' +
        'email.\n' +
        'Luis Figueira\n' + 
        'Senior Program Architect | Salesforce\n' + 
        'Mobile: +44 (0) 7909 610 528\n' + 
        'lfigueira@salesforce.com\n' + 
        '<https://urldefense.proofpoint.com/v2/url?u=3Dhttp-3A__www.salesforce.com&d=\n' + 
        '=3DDwIFaQ&c=3D6zrz5v1771esYjKEWYkRSg&r=3Ddt1ePLp4yrbPyNghVm9PsY5YEdPP7uT7Ja=\n' + 
        '9nPkHZI2g&m=3D0Fhr8bpN4ALUXB9jiTyE-fzANUpPVwlD8LFwxNH4W7M&s=3DjTtdWOetvdQID=\n' + 
        'QpAbT__C6p-DFs5pBNeUqJvekqzB-c&e=3D >\n' + 
        '\n' + 
        '---------- Forwarded message ---------\n' + 
        'From: Rahmathulla Baig <rahmathulla.baig@mulesoft.com>\n' + 
        'Date: Fri, 2 Apr 2021 at 10:19\n' + 
        'Subject: Status Today\n' + 
        'To: Steven Walker <steven.walker@CONFIDENTIAL.COM>, Luis Figueira <\n' + 
        'lfigueira@salesforce.com>, Christopher Bozwell <\n' + 
        'Christopher.Bozwell@CONFIDENTIAL.COM>, Peter Latimer <peter.latimer@CONFIDENTIAL.COM>\n' + 
        'Cc: Mike Jakeman <mjakeman@mulesoft.com>, Yatish Ghedia <\n' + 
        'yghedia@mulesoft.com>\n' + 
        '\n' + 
        '\n' + 
        'Hi All\n' + 
        '\n' + 
        'I have made few changes in the code to avoid some issues in the data coming\n' + 
        'from Curo.\n';
        // The plain text version of the email, if specified by the sender.
        email.plainTextBodyIsTruncated = true;
        // Indicates whether the plain body text is truncated (true) or not (false.)
        email.references = new List<String>{'<CAJJ+yQCnJh3pnJJtuaRcW3GS=B_D5fgnO7P3AQWHcEOJQmbURw@mail.gmail.com>'};
        // The References field of the incoming email. Identifies an email thread. Contains a list of the parent emails' References and message IDs, and possibly the In-Reply-To fields.
        // email.replyTo
        // The email address that appears in the reply-to header.
        email.subject = 'Fwd: Status Today';
        // The subject line of the email, if any.
        email.textAttachments = null;
        // A list of text attachments received with the email, if any.
        email.toAddresses = new List<String>{'lfigueira@salesforce.com'};
        // The email address that appears in the To field.

        return email;
    }
    static testMethod void testParserForContact() {
        // public static List<String> parseBodyForContact(String body) {
        //     List<String> results = new list<String>();
    
        //     return results;
        // }
        Messaging.InboundEmail email = buildRealEmail();

        Test.startTest();
        ExecEmailHandler.EmailContact result = ExecEmailHandler.parseBodyForContact(email.plainTextBody);
        Test.stopTest();

        System.debug(result);
        
        // From: Rahmathulla Baig <rahmathulla.baig@mulesoft.com>
        System.assertEquals('Rahmathulla Baig', result.name, 'Contact name does not match the expected value');
        System.assertEquals('rahmathulla.baig@mulesoft.com', result.emailAddress, 'Contact email address does not match the expected value');
    }
    
    static testMethod void testParserForDate() {
        Messaging.InboundEmail email = buildRealEmail();

        Test.startTest();
        String result = ExecEmailHandler.parseBodyForDate(email.plainTextBody);
        Test.stopTest();

        // Date: Fri, 2 Apr 2021 at 10:19
        System.assertEquals('Fri, 2 Apr 2021 at 10:19', result, 'Date does not match the expected value');
    }

    static testMethod void testParserForSubject() {
        Messaging.InboundEmail email = buildRealEmail();

        Test.startTest();
        String result = ExecEmailHandler.parseBodyForSubject(email.plainTextBody);
        Test.stopTest();

        // Subject: Status Today
        System.assertEquals('Status Today', result, 'Subject does not match the expected value');
    }

    static testMethod void testParserForDifferentEmailFormats() {
                
        // test parseFromString(String fromString)
        /*
        johndoe@example.com
        John <johndoe@example.com>
        John Doe <johndoe@example.com>
        "John Doe" <johndoe@example.com>
        */

        List<String> testStrings = new List<String> {'johndoe@example.com', 'John <johndoe@example.com>', 'John Doe <johndoe@example.com>', '"John Doe" <johndoe@example.com>'}; 

        ExecEmailHandler.EmailContact result = null;

        Test.startTest();
        result = ExecEmailHandler.parseFromString(testStrings[0]);

        System.assertEquals(null, result.name, 'Name does not match');
        System.assertEquals('johndoe@example.com', result.emailAddress, 'Email address does not match');

        result = ExecEmailHandler.parseFromString(testStrings[1]);

        System.assertEquals('John', result.name, 'Name does not match');
        System.assertEquals('johndoe@example.com', result.emailAddress, 'Email address does not match');

        result = ExecEmailHandler.parseFromString(testStrings[2]);

        System.assertEquals('John Doe', result.name, 'Name does not match');
        System.assertEquals('johndoe@example.com', result.emailAddress, 'Email address does not match');

        result = ExecEmailHandler.parseFromString(testStrings[3]);

        System.assertEquals('John Doe', result.name, 'Name does not match');
        System.assertEquals('johndoe@example.com', result.emailAddress, 'Email address does not match');

        Test.stopTest();
    }
}