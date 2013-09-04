/**
* 部屋タイプトリガー処理クラス
**/
public with sharing class TypeOfRoomsTriggerProcess {
	/* 20120930 DELETE
    // E/Bデータは一件だけ登録可能
    public void preCheck(TypeOfRooms__c[] newList, TypeOfRooms__c[] oldList, CommConst.TriggerMethod action){
        //
        if (action == CommConst.TriggerMethod.isInsert) {
            // E/B重複チェックを行う
            Set<TypeOfRooms__c> roomActTypeSet = new Set<TypeOfRooms__c>();
            for (TypeOfRooms__c roomType : newList) {
                if (roomType.ActionType__c == CommConst.ROOMTYPE_EB) {
                    //if (roomActTypeSet.contains(roomType.ActionType__c)) {
                    if (!roomActTypeSet.isEmpty()) {
                        roomType.addError('部屋タイプ（E/B）は一件以上設定することができません。');
                        // 処理終了
                        return;
                    } // End If
                    roomActTypeSet.add(roomType);
                } // End If
            } // End For
            // E/B一件以上チェックを行う
            if (!roomActTypeSet.isEmpty()) {
                // DB中に、既に定義されているかどうかチェックを行う
                List<TypeOfRooms__c> roomTypeLst = [select id from TypeOfRooms__c where ActionType__c = :CommConst.ROOMTYPE_EB limit 1];
                if (!roomTypeLst.isEmpty()) {
                    List<TypeOfRooms__c> errObjList = new List<TypeOfRooms__c>();
                    errObjList.addAll(roomActTypeSet);
                    errObjList[0].addError('部屋タイプ（E/B）は一件以上設定することができません。');
                    // 処理終了
                    return;
                } // End If
            } // End If
        } // End If

    } // End preCheck*/
}