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
        Module_Response__c moduleResp =[SELECT id FROM Module_Response__c WHERE Module__c =: unit.Module__c AND User__c =: UserInfo.getUserId() AND Status__c = 'In Progress'];

        //Si el ModuleResponse no existe le asigno el nuevo module response
        if(moduleResp== null){
            //Creo el ModuleResponse con los datos obtenidos desde la Unit y el User que obtengo mediante la API, luego lo inserto
            moduleResp= new Module_Response__c(User__c = Userinfo.getUserId(), Module__c = unit.Module__c, Status__c = 'In Progress');
            insert moduleResp;

        }
    
        //Creo El UnitResponse y lo inserto los datos a la Db
        Unit_Response__c unitResp = new Unit_Response__c (Module_Response__c = moduleResp.Id, Unit__c = unitId, Status__c = 'Draft');

        unitResp.Tries__c = unitResp.Tries__c ==0 ? unitResp.Tries__c + 1 : 1;
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

    public static TrailWrapper getTrailWrapper(Id trailId){
		//Modulos que estan en el Trail
        List<Module__c> modules = (getModules(trailId));
        //Modulos completados del trail
        Set<Id> completedModules = (getModuleIdsCompleted(trailId, modules));
        //Unidades completadas de los modulos
        Set<Id> completedUnits = (getUnitIdsCompleted(trailId, completedModules));
        //Instancio trail wrapper con trail y modulos
        TrailWrapper trailWrap = new TrailWrapper([SELECT Name, Description__c, Total_Points__c, Total_Time__c FROM Trail__c WHERE Id =: trailId], modules, completedModules, completedUnits);

        return trailWrap;
    }

    private static List<Module__c> getModules(Id trailId){

        //Busco modulos relacionados al trailId recibido como parametro
        List<Trail_Module__c> trailModules = [SELECT Module__c FROM Trail_Module__c WHERE Trail__c =: trailId];
        //Guardo y retorno los ids de los modulos relacionados al trailId
        Set<Id> moduleIds = new Set<Id>();
        for(Trail_Module__c trailModule : trailModules){
            moduleIds.add(trailModule.Module__c);
        }

        return [SELECT Name, Description__c, Module_Points__c, Module_Time__c, (SELECT Name, Content__c FROM Units__r) FROM Module__c WHERE Id in : moduleIds];
    }

    private static Set<Id> getModuleIdsCompleted(Id trailId, List <Module__c> modules){

        //Buscar los modulos completados relacionados al trailId
        List<Module_Response__c> moduleResponses = [SELECT Module__c FROM Module_Response__c WHERE Status__c = 'Complete' AND Module__c in : modules AND User__c =: Userinfo.getUserId()];

        //Guardo y retorno los ids de los modulos completados
        Set<Id> completedModuleIds = new Set<Id>();
        for(Module_Response__c moduleResp : moduleResponses){
            completedModuleIds.add(moduleResp.Module__c);
        }

        return completedModuleIds;
    }
    private static Set<Id> getUnitIdsCompleted(Id trailId,  Set<id> modules){

        //Armo una lista de las unidades relacionadas a los modulos completados y al trailId pasado por parametro
        List<Unit_Response__c> unitResponses = [SELECT Unit__c FROM Unit_Response__c WHERE Is_Complete__c = true AND User__c =: Userinfo.getUserId() AND Module_Response__c in : modules];
        
        //Guardo el id de las unitsCompleted
        Set<Id> completedUnitIds = new Set<Id>();
        for(Unit_Response__c unitResp : unitResponses){
            completedUnitIds.add(unitResp.Unit__c);
        }

        return completedUnitIds;
    }

    public class TrailWrapper{
        //Configuracion
        public Trail__c trail; //Registro de Trail solicitado
        public List<Module__c> modules; //Módulos con Unidades relacionadas
        
        //Transaccional
        public Set<Id> passedModuleIds; //Ids de módulos relacionados al Trail actual en los que el Alumno ya aprobó
        public Set<Id> passedUnitIds; //Ids de Unidades relacionadas a módulos del Trail actual que el Alumno ya aprobó
        public Integer progressTrail; //Porcentaje de progreso del Alumno en el Trail

        public TrailWrapper(Trail__c trail, List<Module__c> modules, Set<Id> passedModuleIds, Set<Id> passedUnitIds){
            this.trail = trail;
            this.modules = modules;
            this.passedModuleIds = passedModuleIds;
            this.passedUnitIds = passedUnitIds;
            this.progressTrail = passedModuleIds.size() / modules.size();
        }
    }

    public static UnitWrapper getUnitWrapper(Id unitId){

        Unit__c unit = [SELECT Name, Content__c, (SELECT id, Content__c FROM Questions__r) FROM Unit__c WHERE Id =: unitId];
        List<Question__c> questions = unit.Questions__r;
        UnitWrapper unitWrap = new UnitWrapper(unit, questions);
        return unitWrap;
    }
    
    public class UnitWrapper {
        
        public Unit__c unit; //Unidad solicitada
        public List <Question__c> questions; // Lista de preguntas de la unidad

        public UnitWrapper (Unit__c unit, List<Question__c> questions){
            this.unit = unit;
            this.questions = questions;
        }
    }
}
