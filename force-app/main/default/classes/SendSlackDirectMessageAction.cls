public class SendSlackDirectMessageAction {

    public class MessageInput {
        @InvocableVariable(required=true description='Slack username (e.g., john.doe)')
        public String username;

        @InvocableVariable(required=true description='Message text to send')
        public String text;
    }

    public class MessageOutput {
        @InvocableVariable(description='True if message was sent successfully')
        public Boolean is_success;

        @InvocableVariable(description='Timestamp of sent message')
        public String message_ts;

        @InvocableVariable(description='Error message if send failed')
        public String error_message;
    }

    @InvocableMethod(label='Send Slack Direct Message To Username')
    public static List<MessageOutput> sendDirectMessage(List<MessageInput> inputs) {
        List<MessageOutput> outputs = new List<MessageOutput>();

        for (MessageInput input : inputs) {
            MessageOutput output = new MessageOutput();
            output.is_success = false;

            try {
                Http http = new Http();

                // STEP 1: Get user list
                HttpRequest userReq = new HttpRequest();
                userReq.setEndpoint('callout:Slack_API/users.list');
                userReq.setMethod('GET');
                userReq.setHeader('Content-Type', 'application/x-www-form-urlencoded');

                HttpResponse userResp = http.send(userReq);
                Map<String, Object> userRespBody = (Map<String, Object>)JSON.deserializeUntyped(userResp.getBody());

                if (userResp.getStatusCode() != 200 || userRespBody.get('ok') != true) {
                    output.error_message = 'Failed to get user list: ' + userRespBody.get('error');
                    outputs.add(output);
                    continue;
                }

                List<Object> members = (List<Object>)userRespBody.get('members');
                String userId = null;

                for (Object memberObj : members) {
                    Map<String, Object> member = (Map<String, Object>)memberObj;
                    String name = (String)member.get('name');
                    system.debug('name = '+name);
                    if (name != null && name.equalsIgnoreCase(input.username)) {
                        userId = (String)member.get('id');
                        break;
                    }
                }

                if (userId == null) {
                    output.error_message = 'User not found: ' + input.username;
                    outputs.add(output);
                    continue;
                }

                // STEP 2: Open DM channel
                HttpRequest openReq = new HttpRequest();
                openReq.setEndpoint('callout:Slack_API/conversations.open');
                openReq.setMethod('POST');
                openReq.setHeader('Content-Type', 'application/json');
                openReq.setBody(JSON.serialize(new Map<String, Object>{
                    'users' => userId
                }));

                HttpResponse openResp = http.send(openReq);
                Map<String, Object> openRespBody = (Map<String, Object>)JSON.deserializeUntyped(openResp.getBody());

                if (openResp.getStatusCode() != 200 || openRespBody.get('ok') != true) {
                    output.error_message = 'Failed to open DM: ' + openRespBody.get('error');
                    outputs.add(output);
                    continue;
                }

                Map<String, Object> channelData = (Map<String, Object>)openRespBody.get('channel');
                String channelId = (String)channelData.get('id');

                // STEP 3: Send message
                HttpRequest msgReq = new HttpRequest();
                msgReq.setEndpoint('callout:Slack_API/chat.postMessage');
                msgReq.setMethod('POST');
                msgReq.setHeader('Content-Type', 'application/json');
                msgReq.setBody(JSON.serialize(new Map<String, Object>{
                    'channel' => channelId,
                    'text' => input.text
                }));

                HttpResponse msgResp = http.send(msgReq);
                Map<String, Object> msgRespBody = (Map<String, Object>)JSON.deserializeUntyped(msgResp.getBody());

                if (msgResp.getStatusCode() == 200 && msgRespBody.get('ok') == true) {
                    output.is_success = true;
                    output.message_ts = (String)msgRespBody.get('ts');
                } else {
                    output.error_message = 'Failed to send message: ' + msgRespBody.get('error');
                }

            } catch (Exception e) {
                output.error_message = 'Exception: ' + e.getMessage();
            }

            outputs.add(output);
        }

        return outputs;
    }
}