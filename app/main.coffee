util = require('util')

String.prototype.replaceAll = (search, replace) ->
    if not replace?
        return @toString()
    @split(search).join(replace)

gongSound = new Audio('gong.mp3')

ringGong = ->
    gongSound.play()

scrollChatToBottom = ->
    $('.chat-container').stop().animate({
        scrollTop: $('.chat-container')[0].scrollHeight
    }, 800)
    
ko.bindingHandlers.checkbox =
    init: (element, valueAccessor, allBindings, data, context) ->
        observable = valueAccessor()

        if not ko.isWriteableObservable(observable)
            throw "You must pass an observable or writeable computed"

        $element = $(element)

        $element.on "click", ->
            observable not observable()
            return

        ko.computed disposeWhenNodeIsRemoved: element, read: ->
            $element.toggleClass "active", observable()
            return

        return


emotes = {
    'Kappa': 'kappa'
    'Colgan', 'colgan'
    'NGCCG', 'ngccg'
    ':O': 'shocked'
    'FrankerZ': 'frankerz'
    'YOLOSwag': 'swag'
    'JordanFitz': 'jordanfitz'
    'BeExcellent': 'lincoln'
    '>:|': 'brooding'
    'BigBrother': 'bigbrother'
    'Tinfoilboy': 'tinfoilboy'
    'FrankerQ': 'fitzdog'
    'NoHair': 'nohair'
    'OneTomato': 'tomato'
}


$ ->
    $('body').tooltip
        selector: '[rel=tooltip]'

    ViewModel = ->
        socket = io.connect('http://tomatoestogether.egg')

        vm = @

        vm.connected = ko.observable(false)
        vm.clock = ko.observable(new Date())
        vm.state = ko.observable(null)
        vm.chatMessages = ko.observableArray([])
        vm.newChatMessage = ko.observable('')
        vm.doneTomatoes = ko.observableArray([])
        vm.nextTomatoTask = ko.observable('')
        vm.nextTomatoTaskInput = ko.observable('')

        vm.pastTomatoes = {}

        vm.clockHeaderMessage = ko.computed ->
            if vm.state == 'tomato' then return 'Tomato Time!'
            if vm.state == 'observing' then return 'Tomato Time!'
            if vm.state == 'tomato' then return 'Tomato Time!'

        # Things to save
        vm.username = ko.observable('guest')
        vm.userColor = ko.observable('#000000')
        vm.playSound = ko.observable(true)


        vm.joinNextTomato = ->
            vm.nextTomatoTask(vm.nextTomatoTaskInput())
            vm.nextTomatoTaskInput('')

        vm.finishTomato = ->
            vm.doneTomatoes.push
                task: vm.nextTomatoTask()
                day: (new Date()).toDateString()
            socket.emit 'message',
                username: vm.username()
                body: "My tomato task: " + vm.nextTomatoTask()
                userColor: vm.userColor()

            vm.nextTomatoTask('')


        vm.restoreFromLocalStorage = ->
            saved = localStorage.getItem('tomatoestogether')
            if saved?
                console.log 'Reading from localStorage' + saved
                saved = JSON.parse(saved)
                vm.username(saved.username or 'guest')
                vm.userColor(saved.userColor or '#000000')
                vm.doneTomatoes(saved.doneTomatoes or [])
                if saved.playSound?
                    vm.playSound(saved.playSound)

            # This has to be done after the values are read
            # or they will be overwritten
            vm.saveToLocalStorage = ko.computed ->
                console.log 'Saving to localStorage.'
                saved =
                    username: vm.username()
                    userColor: vm.userColor()
                    playSound: vm.playSound()
                    doneTomatoes: vm.doneTomatoes()
                console.log saved
                localStorage.setItem('tomatoestogether', JSON.stringify(saved))

        vm.tick = ->
            vm.clock(new Date())

        vm.formattedClock = ko.computed ->
            return util.formatCurrentTime(vm.clock())

        vm.todaysTomatoes = ko.computed ->
            todays = []
            today = new Date().toDateString()
            for tomato in vm.doneTomatoes()
                if tomato.day == today
                    todays.push(tomato)
            return todays

        vm.formattedTime = ko.computed ->
            [minutesLeft, secondsLeft, state] = util.tomatoTimeFromHourTime(vm.clock())
            if vm.state()? and vm.state() != state
                if vm.playSound()
                    ringGong()
                if state == 'break'
                    # Finish the current tomato if there is one
                    vm.finishTomato()
            vm.state(state)
            return util.formatTomatoClock(minutesLeft, secondsLeft)

        vm.sendMessage = (form) ->
            scrollChatToBottom()
            socket.emit 'message',
                username: vm.username()
                body: vm.newChatMessage()
                userColor: vm.userColor()
            vm.newChatMessage('')

        emoteSrc = (emoteFile) ->
            return '<img src="emotes/' + emoteFile + '.png"/>'

        vm.addMessage = (message) ->
            for emoteKeyword, emoteFile of emotes
                message.body = message.body.replaceAll(emoteKeyword, emoteSrc(emoteFile))
            vm.chatMessages.push(message)


        setInterval(vm.tick, 1000)

        socket.on 'hello', (data) ->
            vm.connected(true)
            for message in data.messages
                vm.addMessage(message)
            scrollChatToBottom()
        socket.on 'message', (message) ->
            vm.addMessage(message)

        vm.restoreFromLocalStorage()

        null

    ko.applyBindings(new ViewModel)
