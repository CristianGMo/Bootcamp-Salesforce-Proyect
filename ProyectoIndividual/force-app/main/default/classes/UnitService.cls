public with sharing class UnitService {

    public static Boolean registerUnitResponse(Id unitId, String jsonAnswer) {

        Boolean res = true;
        //Guardo un estado de la db
        Savepoint savepoint = Database.setSavepoint();
        
        //Utilizo try-chatch para capturar cualquier excepción
        try{
            //Busco en mi db la unidad basandome en el Id que viene como parametro(obtengo el modulo al que pertenece y las preguntas que tiene relacionadas)
        Unit__c unit = [SELECT Module__c, id, (SELECT id, Name from Questions__r) FROM Unit__c WHERE id=:unitId];

        //Verifico si existe un module response 
        Module_Response__c moduleResp =[SELECT id FROM Module_Response__c WHERE Module__c =: unit.Module__c AND User__c =: UserInfo.getUserId() AND Status = 'In Progress'];

        //Si el ModuleResponse no existe le asigno el nuevo module response
        if(!moduleResp){
            //Creo el ModuleResponse con los datos obtenidos desde la Unit y el User que obtengo mediante la API, luego lo inserto
            moduleResp= new Module_Response__c(User__c = Userinfo.getUserId(), Module__c = unit.Module__c, Status__c = 'In Progress');
            insert moduleResp;

        }
    
        //Creo El UnitResponse y lo inserto los datos a la Db
        Unit_Response__c unitResp = new Unit_Response__c (Module_Response__c = moduleResp.Id, Unit__c = unitId, Status__c = 'Draft');

        unitResp.Tries__c = !unitResp.Tries__c.isEmpty() ? unit.Unit_Responses__c[0].Tries__c + 1 : 1;
        insert unitResp;

        //Uso API para transformar un json en un Map (IdQuestion : IdAnswer).En el json vienen las respuestas elegidas en cada pregunta de la unidad.
        Map<Id,Id> AnswerMap = (Map<Id,Id>)JSON.deserializeStrict(jsonAnswer, Map<Id,Id>.class);

        //Creo una lista de QuestionResponse donde guardaremos el Id de las question que pertenezcan a la unidad en la que nos encontramos.
        List<Question_Response__c> questionResponseList = new List<Question_Response__c>();

        for (Question__c question : unit.Questions__r){
           Question_Response__c questionResponse = new Question_Response__c (Question__c = question.id, Unit_Response__c = unitId, Answer__c = AnswerMap.get(question.id));
           questionResponseList.add(questionResponse);
       }
         insert questionResponseList;

         unitResp.Status__c = 'Answered';
         update unitResp;
        }
        catch(Exception e){
            Database.rollback(savepoint);
            res = false;
            throw e;
            
        }
        return res;
        
    }
}
