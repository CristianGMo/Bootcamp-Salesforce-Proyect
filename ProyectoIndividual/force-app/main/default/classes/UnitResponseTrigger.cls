public with sharing class UnitResponseTrigger {

    public static void onBeforeUpdate(List <Unit_Response__c> unitResponseList, Map<id, Unit_Response__c> oldUnitResponseMap) {
        
        //Creo una lista donde se guardaran las unit response que cumplan con los requisitos del for loop.
        List <Unit_Response__c> ansUnitRespList = new List <Unit_Response__c> ();

        for(Unit_Response__c unitResponse : unitResponseList){
            if(unitResponse.Status__c== 'Answered' && oldUnitResponseMap.get(unitResponse.Id).Status__c== 'Draft'){
                ansUnitRespList.add(unitResponse);
            }
        }
    }

    public static void onAfterUpdate(List <Unit_Response__c> unitResponseList, Map<id, Unit_Response__c> oldUnitResponseMap) {
        
        List <Unit_Response__c> correctUnitResponseList = new List <Unit_Response__c>();

        for(Unit_Response__c UnitResponse : unitResponseList){
            if(UnitResponse.Is_Complete__c && !oldUnitResponseMap.get(UnitResponse.id).Is_Complete__c){
               correctUnitResponseList.add(UnitResponse);
            }    
        }

        updateUserPoints(correctUnitResponseList);
    }

    //Method que verifica si las respuestas selecionadas son las correctas, si lo son, entonces el status de Unit Response pasara a ser complete = true
    private static void validateAnswers (List <Unit_Response__c> unitResponseList){

        //Creo un map con key Id y value Unit Response, que tambien traera la respuesta correcta de las preguntas
        Map <id, Unit_Response__c> dbUnitRespMap = new Map <id, Unit_Response__c>([SELECT Id, Unit__r.Points__c, (SELECT Id, Answer__r.Is_Correct__c FROM Question_Responses__r ) FROM Unit_Response__c WHERE Id in : UnitResponseList]);

        for (Unit_Response__c unitResponse : unitResponseList){
            
            unitResponse.Is_Complete__c = true;

            for(Question_Response__c questionResp : dbUnitRespMap.get(unitResponse.id).Question_Responses__r){
                if(questionResp.Answers__r.Is_Correct__c!=true){
                    unitResponse.Is_Complete__c = false;
                    break;
                }
                unitResponse.Status__c = 'Success';
            }

            if(unitResponse.Status__c=='Success'){
                if(unitResponse.Tries__c == 1){
                    unitResponses.Points__c = unitResponse.Unit__r.Points__c;
                }
                else if(unitResponse.Tries__c ==2 ){
                    unitResponse.Points__c = unitResponse.Unit__r.Points__c/2;
                }
                else{
                    unitResponse.Points__c = unitResponse.Unit__r.Points__c/4;
                }
            }
        }
    }

    //Actualizar los puntos de los ususarion en la base de datos
    private static void updateUserPoints (List <Unit_Response__c> UnitResponseList){

        Set <Id> userIds = new Set <Id>();
        //Junto los Id de los users en un set
        for(Unit_Response__c unitResponse : unitResponseList){
           userIds.add(unitResponse.User__c);
        }

        //Users que estan en la UnitResp List
        Map <Id, User> usersMap = new Map<Id, User>([SELECT id, Points__c FROM User WHERE Id in : userIds]);

        //Actualizar los puntos en db
        for (Unit_Response__c UnitResponse : unitResponseList){
            User user = userMap.get(UnitResponse.User__c);
            user.Points__c += UnitResponse.Points__c;
        }

        update usersMap.values();
    }

    /* private static void calculateRank (List<User> users){

    } */

    
}
