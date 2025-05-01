public class AgentforceRequestHandler {

    public class RequestWrapper {
        @InvocableVariable(required=true)
        public String inputQuery;
        @InvocableVariable(required=true)
        public String quoteRecordId;
    }
    
    public class ResponseWrapper {
        @InvocableVariable
        public String agentResponse;
    }
    
    @InvocableMethod(label='Handle Document Approval Request' description='Generates agent response based on input query')
    public static List<ResponseWrapper> handleContractDocument(List<RequestWrapper> requestList) {
        
        List<ResponseWrapper> responseList = new List<ResponseWrapper>();
		//String req=String.ValueOf(requestList[0]);
        //String quoteRecordId=String.ValueOf(requestList[1]);

        for (RequestWrapper req : requestList) {
            Invocable.Action action = Invocable.Action.createCustomAction(
                'generateAiAgentResponse', 
                'Deal_Guard_Agent'
            );

            action.setInvocationParameter('userMessage', req.inputQuery);

            List<Invocable.Action.Result> actionResults = action.invoke();
            Invocable.Action.Result actionResult = actionResults[0];

            if (actionResult.isSuccess()) {
                System.debug('Session Id: ' + actionResult.getOutputParameters().get('sessionId'));
                System.debug('Agent Response: ' + actionResult.getOutputParameters().get('agentResponse'));
                
                
				Map<String, Object> proposalData = (Map<String, Object>) JSON.deserializeUntyped((String)actionResult.getOutputParameters().get('agentResponse'));

				String type = (String)proposalData.get('type');
				String value = (String)proposalData.get('value');

				System.debug('type: ' + type);
				System.debug('value ' + value);
                

                
                    //call slack action
                    Invocable.Action action1 = Invocable.Action.createCustomAction(
                		'generateAiAgentResponse', 
                		'Deal_Guard_Agent'
            		);
                System.debug('text: '+value+' send the response to slack channel #legal in Winfomi agent spark workspace');
                    //action1.setInvocationParameter('userMessage', value+' send the response to slack channel #legal in Winfomi agent spark workspace');
                	 action1.setInvocationParameter('userMessage', 'Response: '+ value+' If there is any discrepency in the Response if its only discount related issue send the response to to slack channel #finance in Winfomi Agent Apark workspace or If there is any discrepency in the Response like only Payment terms related issue send the response to to slack channel #finance in Winfomi Agent Spark workspace. If the is issue related to Discount and Payment terms then update quote RecordId '+req.quoteRecordId+' status field Rejected  or if there is no issue with the discount and Payment terms the update the quote recordID '+req.quoteRecordId+' status to Approved');

					List<Invocable.Action.Result> actionResults1 = action1.invoke();
            		Invocable.Action.Result actionResult1 = actionResults1[0];
                System.debug('Agent Response: ' + actionResult1.getOutputParameters().get('agentResponse'));
                    

            } else {
                System.debug(actionResult.getErrors());
                // You could optionally handle error cases too
            }
        }

        return responseList;
    }
}