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
        var newUserBase = [User]()
        _ = usersBase.map { user in
            if user != user{ //если по юзеру находим наш звонок
                newUserBase.append(user)
            }
        }
        usersBase = newUserBase
    }
    
    func execute(action: CallAction) -> CallID? {
        var call: Call //объявляем переменную для создания звонка
        var newCallBase = [Call]() //инициализируем пустую новую базу звонков
        var uid: CallID = UUID() //создаем UID для возврата в него ид звонка из замыкания
        //перебираем действия
        switch action {
        case .start(from: let from, to: let to):
            //проверяем, что оба пользователи зарегистрированы
            if !usersBase.contains(from) && !usersBase.contains(to){
                return nil
            }
            //если только один зареган, то ошибка звонка
            if !usersBase.contains(from) || !usersBase.contains(to) {
                call = Call(id: uid, incomingUser: from, outgoingUser: to, status: .ended(reason: .error)) //инициализируем новый звонок
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
            //FIXME: перезапись БД
            //пока нашел такой выход, перебрать все звонки, если нашли наш звонок, поменять у него статус и вернуть новую структуру с измененными звонками
            //если бы по условию был класс звонка, было бы проще, можно было бы поменять просто статус у найденного
            //на реальном проекте это бы была глина (возможно поменяю когда решу таск)
            if !usersBase.contains(from){
                _ = callBase.map { call in
                    if call.outgoingUser == from{ //если по юзеру находим наш звонок в базу добаляем этот звонок с новым статусом
                        newCallBase.append(Call(id: call.id,
                                                incomingUser: call.incomingUser,
                                                outgoingUser: call.outgoingUser,
                                                status: .ended(reason: .error)))
                        uid = call.id
                    }else {
                        newCallBase.append(call) //если не наш звонок, то просто добаляем на то же место
                    }
                }
                callBase = newCallBase
                return nil
            }else {
                _ = callBase.map { call in
                    if call.outgoingUser == from{ //если по юзеру находим наш звонок в базу добаляем этот звонок с новым статусом
                        newCallBase.append(Call(id: call.id,
                                                incomingUser: call.incomingUser,
                                                outgoingUser: call.outgoingUser,
                                                status: .talk))
                        uid = call.id
                    }else {
                        newCallBase.append(call) //если не наш звонок, то просто добаляем на то же место
                    }
                }
                callBase = newCallBase
                return uid
            }

            
        case .end(from: let from):
            _ = callBase.map { call in
                //если по юзеру находим наш звонок в базу добаляем этот звонок с новым статусом
                if call.incomingUser == from || call.outgoingUser == from{
                    var reason: CallEndReason = .end
                    if call.status == .talk { reason = .end}
                    if call.status == .calling {reason = .cancel}
                    newCallBase.append(Call(id: call.id,
                                            incomingUser: call.incomingUser,
                                            outgoingUser: call.outgoingUser,
                                            status: .ended(reason: reason)))
                    uid = call.id
                }else {
                    newCallBase.append(call) //если не наш звонок, то просто добаляем на то же место
                }
            }
        }
        callBase = newCallBase
        return uid
    }
    
    func calls() -> [Call] {
        return callBase
    }
    
    func calls(user: User) -> [Call] {
        var callsUser = [Call]()
        _ = callBase.map { call in
            if call.incomingUser == user || call.outgoingUser == user{
                callsUser.append(call)
            }
        }
        return callsUser
    }
    
    func call(id: CallID) -> Call? {
        let resultCall = callBase.map { call -> Call? in
            guard call.id == id else { return nil }
            return call
        }
        let result = resultCall.filter { call in
            call != nil
        }
        return result.first ?? nil
    }
    
    func currentCall(user: User) -> Call? {
        //через замыкание находим и возвращаем текущий звонок
        let current = callBase.map { call -> Call? in
            guard (call.incomingUser == user || call.outgoingUser == user) &&
                    (call.status == .calling || call.status == .talk)
            else { return nil}
            return call
        }
        let result = current.filter { call in
            call != nil
        }
        return result.first ?? nil
    }
    
}

extension CallStation {
    
    //test
}
