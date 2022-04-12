public with sharing class UnitService {

    public static Boolean registerUnitResponse(Id unitId, String jsonAnswer) {

        //Busco en mi db la unidad basandome en el Id que viene como parametro(obtengo el modulo al que pertenece y las preguntas que tiene relacionadas)
        Unit__c unit = [SELECT Module__c, id, (SELECT id, Name from Questions__r) FROM Unit__c WHERE id=:unitId];

        //Verifico si existe un module response 
        Module_Response__c moduleResp =[SELECT id FROM Module_Response__c WHERE Module__c =: unit.Module__c AND User__c =: UserInfo.getUserId() AND Status = 'In Progress'];

        //Si el ModuleResponse no existe le asigno el nuevo module response
        if(!moduleResp){
            //Creo el ModuleResponse con los datos obtenidos desde la Unit y el User que obtengo mediante la API, luego lo inserto
            moduleResp= new ModuleResponse__c(User__c = Userinfo.getUserId(), Module__c = unit.Module__c, Status__c = 'In Progress');
            insert moduleResp;

        }
    
        //Creo El UnitResponse y lo inserto los datos a la Db
        UnitResponse__c unitResp = new UnitResponse (Module_Response__c = moduleResp.Id, Unit__c = unitId, Status__c = 'Draft');
        insert unitResp;

        //Uso API para transformar un json en un Map (IdQuestion : IdAnswer).En el json vienen las respuestas elegidas en cada pregunta de la unidad.
        Map<Id,Id> AnswerMap = (Map<Id,Id>)JSON.deserializeStrict(jsonAnswer, Map<Id,Id>.class);

        //Creo una lista de QuestionResponse donde guardaremos el Id de las question que pertenezcan a la unidad en la que nos encontramos.
        List<QuestionResponse__c> questionResponseList = new List<QuestionResponse__c>();

        //En vez de verificar si las preguntas de la unidad vienen todas en el json puedo poner una restriccion? Por ejemplo que no se habilite el boton de enviar hasta que todas las respuestas esten respondidas como en trailhead.(PREGUNTAR)
        for (Question__c question : unit.Questions__r){
           QuestionResponse__c questionResponse = new QuestionResponse__c (Question__c = question.id, UnitResponse = unitId, Answer__c = AnswerMap.get(question.id));
           questionResponseList.add(questionResponse);
       }
         insert questionResponseList;
    }
}
