Global class ExecEmailHandler implements Messaging.InboundEmailHandler {
 
    Global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope env ) {
    
        // Create an inboundEmailResult object for returning 
        // the result of the email service.
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
            
        // Create contact and lead lists to hold all the updated records.
        // List<Contact> lc = new List <contact>();
        // List<Lead> ll = new List <lead>();

        System.debug(email);
        System.debug(env);

        try {

            EmailContact potentialContact = parseBodyForContact(email.plainTextBody);
            System.debug('Potential email contact = ' + potentialContact);
            
            List<Contact> contacts = [select Id from Contact where Email = :potentialContact.emailAddress];
            
            String subject = parseBodyForSubject(email.plainTextBody);
            System.debug('Subject = ' + subject);
            
            Case newCase = new Case(Subject = subject, Description = email.plainTextBody);
            
            if(contacts.size()>0) {
                // existing contact found
                System.debug('Existing contact found');
                newCase.ContactId = contacts[0].Id;
            } else {
                // no contact found
                System.debug('No contact found');
                newCase.SuppliedEmail = potentialContact.emailAddress;
                newCase.SuppliedName = potentialContact.name;
            }

            // TODO should check whether it's creating a new case or updating an existing case
            // TODO should attach the email to the case
            insert newCase;
            
            result.success = true;
        }

        catch(Exception e) {
            result.success = false;
            result.message = e.getMessage();
        }

        return result;
    }   

    @TestVisible
    private static EmailContact parseBodyForContact(String body) {
        EmailContact resultContact = new EmailContact();
        String fromString = '';

        Pattern fromPattern = Pattern.compile('(?m)(?i)^from: (.*)'); 
        Matcher fromMatcher = fromPattern.matcher(body);

        if(fromMatcher.find()) {
            System.debug(fromMatcher);
            System.debug(fromMatcher.start());
            System.debug(fromMatcher.groupCount());
            if(fromMatcher.groupCount()>0) {
                fromString = fromMatcher.group(1);
                resultContact = parseFromString(fromString);
            }
        }

        return resultContact;
    }

    @TestVisible
    private static EmailContact parseFromString(String fromString) {
        EmailContact resultContact = new EmailContact();

        // get name and email from fromString
        /*
        johndoe@example.com
        John <johndoe@example.com>
        John Doe <johndoe@example.com>
        "John Doe" <johndoe@example.com>
        */

        Pattern contactPattern = Pattern.compile('(?:"?([^"]*)"?\\s)?(?:<?(.+@[^>]+)>?)'); 
        Matcher contactMatcher = contactPattern.matcher(fromString);
        
        if(contactMatcher.find()) {
            System.debug(contactMatcher);
            System.debug(contactMatcher.start());
            System.debug(contactMatcher.groupCount());
            if(contactMatcher.groupCount() == 2) {
                resultContact.name = contactMatcher.group(1);
                resultContact.emailAddress = contactMatcher.group(2);
            }
        }

        return resultContact;        
    }

    @TestVisible
    private static String parseBodyForDate(String body) {
        String result = null;

        Pattern myPattern = pattern.compile('(?m)(?i)^date: (.*)'); 
        Matcher myMatcher = myPattern.matcher(body);

        if(myMatcher.find()) {
            System.debug(myMatcher);
            System.debug(myMatcher.start());
            System.debug(myMatcher.groupCount());
            if(myMatcher.groupCount()>0) {
                result = myMatcher.group(1);
            }
        }

        return result;
    }

    @TestVisible
    private static String parseBodyForSubject(String body) {
        String result = null;

        Pattern myPattern = pattern.compile('(?m)(?i)^subject: (.*)'); 
        Matcher myMatcher = myPattern.matcher(body);

        if(myMatcher.find()) {
            System.debug(myMatcher);
            System.debug(myMatcher.start());
            System.debug(myMatcher.groupCount());
            if(myMatcher.groupCount()>0) {
                result = myMatcher.group(1);
            }
        }

        return result;
    }

    @TestVisible class EmailContact {
        @TestVisible String name;
        @TestVisible String emailAddress;
    }
}