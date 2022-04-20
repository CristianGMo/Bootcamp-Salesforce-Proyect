trigger UnitResponseTrigger on Unit_Response__c (before update, after update) {

    if(Trigger.isBefore){
        //Le pasamos a la clase del trigger el Trigger.new (seran los valores nuevos) y Trigger.oldMap (valores antiguos para comparar)
        UnitResponseTrigger.onBeforeUpdate(Trigger.new, Trigger.oldMap);
    }
    else{
        UnitResponseTrigger.onAfterUpdate(Trigger.new, Trigger.oldMap);
    }

}