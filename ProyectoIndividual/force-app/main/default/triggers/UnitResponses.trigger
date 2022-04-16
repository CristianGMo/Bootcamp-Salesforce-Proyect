trigger UnitResponses on Unit_Response__c (before update) {

    //Le pasamos a la clase del trigger el Trigger.new (seran los valores nuevos) y Trigger.oldMap (valores antiguos para comparar)
    UnitResponseTrigger.onBeforeUpdate(Trigger.new, Trigger.oldMap);

}