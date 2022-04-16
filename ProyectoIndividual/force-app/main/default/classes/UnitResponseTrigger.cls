public with sharing class UnitResponseTrigger {

    public static void onBeforeUpdate(List <Unit_Response__c> unitResponseList, Map<id, Unit_Response__c> oldUnitResponseMap) {
        
        //Creo una lista donde se guardaran las unit response que cumplan con los requisitos del for loop.
        List <Unit_Response__c> ansUnitRespList = new List <Unit_Response__c> ();

        for(Unit_Response__c unitResponse : unitResponseList){
            if(unitResponse.Status__c== 'Answered' && oldUnitResponseMap.getValue(unitResponse.id).Status__c== 'Draft'){
                ansUnitRespList.add(unitResponse);
            }
        }
    }
    //Method que verifica si las respuestas selecionadas son las correctas, si lo son, entonces el status de Unitd Response pasara a ser complete = true
    private static void validateAnswers (List <Unit_Response__c> unitResponseList){

        Map <id, Unit_Response__c> dbUnitRespMap = new Map <id, Unit_Response__c>([SELECT Id, (SELECT Id, Answer__r.Is_Correct__c FROM Question_Responses__r ) FROM Unit_Response__c WHERE Id in : UnitResponseList]);

        for (Unit_Response__c unitResponse : unitResponseList){
            
            UnitResponse.Answers__r.Is_Correct__c = true;

            for(Question_Response__c questionResp : dbUnitRespMap.get(unitResponse.id).Question_Responses__r){
                if(!questionResp.Answers__r.Is_Correct__c){
                    unitResponse.Status__c = false;
                    break;
                }
            }
        }
    }

    
}
