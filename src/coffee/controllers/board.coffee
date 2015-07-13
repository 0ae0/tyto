module.exports = (BoardList, App, Backbone, Marionette) ->
  BoardList.Router = Marionette.AppRouter.extend
    appRoutes:
      'board/:board'                        : 'showBoard'
      'board/:board/task/:task'             : 'editTask'
      'board/:board/task/:task?fresh=:isNew': 'editTask'
      '*path'                               : 'defaultDrop'

  BoardList.Controller = Marionette.Controller.extend
    initialize: ->
      this.boardList = App.boardList
      return

    defaultDrop: ->
      # NOTE :: This is required if we wish to auto route user to a board.
      yap 'do me', Tyto.boardList.length
      Tyto.selectView = new App.Layout.Select
        collection: Tyto.boardList
      Tyto.root.showChildView 'content', Tyto.selectView
      return
      # if this.boardList.length > 0 and window.location.hash is ''
      #   Tyto.vent.on 'history:started', ->
      #     id = that.boardList.first().get 'id'
      #     App.navigate 'board/' + id,
      #       trigger: true

    start: ->
      that = this
      this.showMenu this.boardList

      # Cookie banner must be accepted before any functionality is possible.
      # this.showCookieBanner()


      return

    showCookieBanner: ->
      if window.localStorage and !window.localStorage.tyto
        ###
          Show cookie banner by creating a temporary region and showing
          the view.
        ###
        Tyto.root.getRegion('header')
          .$el
          .prepend $('<div id="cookie-banner"></div>')
        Tyto.root.addRegion 'cookie', '#cookie-banner'
        Tyto.CookieBannerView = new App.Layout.CookieBanner()
        Tyto.root.showChildView 'cookie', Tyto.CookieBannerView

        return

    showMenu: (boards) ->
      Tyto.menuView = new App.Layout.Menu
        collection: boards
        model     : Tyto.currentBoard
      Tyto.root.showChildView 'menu', Tyto.menuView
      return

    showBoard: (id) ->
      # On a show board. Need to pull in all the columns and tasks for a board
      # And send them through to the view...
      Tyto.currentBoard = model = this.boardList.get id
      if model isnt `undefined`
        cols = Tyto.columnList.where
          boardId: model.id
        tasks = Tyto.taskList.where
          boardId: model.id

        Tyto.currentTasks.reset tasks
        Tyto.currentCols.reset cols

        Tyto.boardView = new App.Layout.Board
          model     : model
          collection: Tyto.currentCols
          options   :
            tasks: Tyto.currentTasks

        Tyto.vent.trigger 'board:change', Tyto.currentBoard

        App.root.showChildView 'content', Tyto.boardView
      else
        App.navigate '/'

    editTask: (bId, tId, isNew) ->
      board      = Tyto.boardList.get bId
      renderTask = ->
        taskToEdit     = Tyto.taskList.get tId
        Tyto.editView  = new App.Layout.Edit
          model  : taskToEdit
          boardId: bId
          isNew  : isNew
        App.root.showChildView 'content', Tyto.editView

      ###
        Wrapped in case user refreshes on an edit view in which case
        Tyto.taskList would need to fetch again.
      ###
      if Tyto.taskList.get(tId) is `undefined`
        Tyto.taskList.fetch().done ->
          renderTask()
      else
        renderTask()

  # Here just instantiate controller and start it up
  App.on 'start', ->
    Tyto.controller        = new BoardList.Controller()
    Tyto.controller.router = new BoardList.Router
      controller: Tyto.controller
    Tyto.controller.start()
    return

  return
