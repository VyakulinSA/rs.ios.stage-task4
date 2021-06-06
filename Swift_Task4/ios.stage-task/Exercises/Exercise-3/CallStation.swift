import Foundation

final class CallStation {
    var usersBase: [User] = [] //создаем массив для хранения user
    var callBase: [Call] = [] //создадим массив для хранения звонков
}

extension CallStation: Station {
    
    func users() -> [User] {
        return usersBase //просто возвращаем всех юзеров
    }
    
    func add(user: User) {
        //если в базе еще нет такого юзера добавляем, если есть, ничего не делаем
        if !usersBase.contains(user){
            usersBase.append(user)
        }
    }
    
    func remove(user: User) {
        usersBase.removeAll { user in
            user == user
        }
    }
    
    func execute(action: CallAction) -> CallID? {
        var call: Call //объявляем переменную для создания звонка
        let uid: CallID = UUID() //создаем UID для возврата в него ид звонка из замыкания
        switch action {
        case .start(from: let from, to: let to):
            //проверяем, что оба пользователи зарегистрированы
            if !usersBase.contains(from) && !usersBase.contains(to){ return nil }
            //если только один зареган, то ошибка звонка
            if !usersBase.contains(from) || !usersBase.contains(to) {
                call = Call(id: uid, incomingUser: from, outgoingUser: to, status: .ended(reason: .error))
                callBase.append(call) //добавляем в базу новый звонок
                return uid
            }
            
            let fromCurrentCall = currentCall(user: from) //получаем активные звонки у первого (не обязательно но вдруг)
            let toCurrentCall = currentCall(user: to) //получаем активные звонки у второго
            
            //если у одного или второго на момент звонка есть активные звонки, то создаем вызов который завершается со статусом userBusy
            if fromCurrentCall != nil || toCurrentCall != nil {
                call = Call(id: uid, incomingUser: from, outgoingUser: to, status: .ended(reason: .userBusy)) //инициализируем новый звонок
                callBase.append(call) //добавляем в базу новый звонок
            }else {
                call = Call(id: uid, incomingUser: from, outgoingUser: to, status: .calling) //инициализируем новый звонок
                callBase.append(call) //добавляем в базу новый звонок
            }
            return uid
            
        case .answer(from: let from):
            //если направлена команда ответа на звонок, значит в базе обновляем статус звонка
            if !usersBase.contains(from){ //если в базе нет юзера, то звонок завершаем с ошибкой
                _ = changeStatusForCall(from: from, action: .answer(from: from), newStatus: .ended(reason: .error))
                return nil
            }else {
                return changeStatusForCall(from: from,action: .answer(from: from), newStatus: .talk)
            }
            
        case .end(from: let from):
            return changeStatusForCall(from: from,action: .end(from: from), newStatus: .ended(reason: .end))
        }
    }
    
    
    func calls() -> [Call] {
        return callBase
    }
    
    func calls(user: User) -> [Call] {
        return callBase.filter { call in
            call.incomingUser == user || call.outgoingUser == user
        }
    }
    
    func call(id: CallID) -> Call? {
        return callBase.first { call in
            call.id == id
        }
    }
    
    func currentCall(user: User) -> Call? {
        return callBase.first { call in
            return (call.incomingUser == user || call.outgoingUser == user) && (call.status == .calling || call.status == .talk)
        }
    }
}

extension CallStation {
    
    private func changeStatusForCall(from: User, action: CallAction, newStatus: CallStatus) -> CallID? {
        var reasonStatus = newStatus
        let indexOfCall: Array<Call>.Index?
        //получаем индекс звонка в массиве
        if action == .end(from: from) {
            indexOfCall = callBase.firstIndex { call in
                call.incomingUser == from || call.outgoingUser == from
            }
        }else {
            indexOfCall = callBase.firstIndex { call in
                call.outgoingUser == from
            }
        }
        guard let indexOfCall = indexOfCall else { return nil}
        let callingCall = callBase[indexOfCall]//получаем звонок из массива
        //создаем замену звонка (на основе полученного звонка), т.к. это структура и его надо удалить из базы и заменить на другой
        if action == .end(from: from) {
            if callingCall.status == .talk { reasonStatus = .ended(reason: .end)}
            if callingCall.status == .calling {reasonStatus = .ended(reason: .cancel)}
        }

        let call = Call(id: callingCall.id, incomingUser: callingCall.incomingUser, outgoingUser: callingCall.outgoingUser, status: reasonStatus)
        callBase.remove(at: indexOfCall) //удаляем старый звонок
        callBase.insert(call, at: indexOfCall) //добавляем звонок с замененым статусом
        return call.id
        
    }
}
