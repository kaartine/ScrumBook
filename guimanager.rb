# Copyright (C) 2011 by Jukka Kaartinen

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'tk'
require 'tkextlib/tile'


require './configurations'
require './helpfunctions'
require './burndownview'
require './backlogview'

class GuiManager

  attr_accessor :project

  include BurnDownView
  include BacklogView

  def initialize(project)
    @project = project
    @effortsRemainingLabel = Array.new
    @effortsRemaining = Array.new
  end

  def createGui( controller )
    @controller = controller

    @root = TkRoot.new
    @root.title = TITLE

    createMenu
    createTabs
  end

  def refreshView(selected_item = nil?)
    refreshSprint(selected_item)
    refreshTaskEditor

    refreshTitle
  end

  def refreshTitle
    new_title = TITLE
    new_title += ' *' unless @project.saved?
    @root.title = new_title
  end

  def refreshSprint(selected_item = nil)
    @project.sprint = @projectSprint.value

    id = @projectSprint.value.to_i
    logger "sprint_id: " + id.to_s
    @project.sprint = id

    items = @sprintTaskTree.children('')
    @sprintTaskTree.delete(items)

    @effortsRemaining.clear

    fillTasks(@project.tasks[id], nil)

    @project.sprintlength.times.each do |i|
      @effortsRemainingLabel[i].text = @effortsRemaining[i]
    end

    logger "selected_item: #{selected_item}"
    @sprintTaskTree.focus_item(selected_item) unless selected_item.nil?

    logger "project: " + @project.inspect, 4
  end

  def fillTasks(tasks, parent)
    if tasks
      tasks.each do |t|
        logger "add task id: #{t.task_id}", 4
        root = ''
        root = parent.task_id unless parent.nil?
        temp = @sprintTaskTree.insert(root, 'end', :id => t.task_id, :text => t.name, :tags => ['clickapple'])
        @sprintTaskTree.set( t.task_id, 'committer', t.committer)
        @sprintTaskTree.set( t.task_id, 'status', t.status)
        @sprintTaskTree.itemconfigure(t.task_id, 'open', true)

        @project.sprintlength.times.each do |i|
          @sprintTaskTree.set(t.task_id, "w#{i}", t.duration[i])
          @effortsRemaining.push(0) if @effortsRemaining[i].nil?
          @effortsRemaining[i] += t.duration[i]
        end

        @sprintTaskTree.tag_bind('clickapple', 'ButtonRelease-1', @changeTask)
        logger "t.tasks: #{t.tasks.inspect}", 4
        fillTasks(t.tasks, t)
      end
    end
  end

  def refreshTaskEditor
    item = @sprintTaskTree.focus_item()
    logger "selected: " + item.inspect
    if !item.nil?
      task = @project.findTask(item.to_i)

      logger task.inspect, 4

      @taskName.value = task.name
      @taskCommitter.value = task.committer
      @taskStatus.value = task.status
      @project.sprintlength.times.each  do |i|
        @taskDuration[i].value = task.duration[i]
      end
    else
      @taskName.value = ""
      @taskCommitter.value = ""
      @taskStatus.value = ""
      @project.sprintlength.times.each  do |i|
        @taskDuration[i].value = ""
      end
    end
  end

  def openInformationDialog(title, text)
    Tk.messageBox(
      'type'    => "ok",
      'icon'    => "info",
      'title'   => title,
      'message' => text
    )
  end

  def startMainLoop
    Tk.mainloop
  end

  private

  def createTabs
    tab = Tk::Tile::Notebook.new(@root) do
      width WIDTH
      height HEIGHT
    end

    createConfigTab(tab)
    createSprintTab(tab)
    createBurnDownTab(tab)
    create_backlog_tab(tab)

    tab.add @backlog_tab, :text => 'Backlog'
    tab.add @sprintTab, :text => 'Sprint'
    tab.add @burnDownTab, :text => 'Burn Down'
    tab.add @configsTab , :text => 'Configs'

    tab.pack("expand" => "1", "fill" => "both")
  end

  def updateTask(item_id)
    logger "updateTask: " + item_id.to_s
    task = @project.findTask(item_id)

    if !task.nil?
      task.name = @taskName.value
      task.committer = @taskCommitter.value
      task.status = @taskStatus.value
      @project.sprintlength.times.each  do |i|
        task.addDuration(i, @taskDuration[i].value.to_i)
        logger "task update w#{i}: " + task.duration[i].to_s
      end
    end
  end

  def createSprintTab(tab)
    @sprintTab = Tk::Tile::Frame.new(tab) {padding "3 3 12 12"}.grid(:sticky => 'nws')
    TkGrid.columnconfigure( @sprintTab, 0, :weight => 1 )
    TkGrid.rowconfigure( @sprintTab, 0, :weight => 1 )

    @changeSprint = Proc.new {
      refreshView
    }

    @changeTask = Proc.new {
      refreshTaskEditor
    }

    #sprint selector
    sprintEntry = TkSpinbox.new(@sprintTab) {
      to 800
      from 0
      increment 1
      width 10
    }
    sprintEntry.bind("ButtonRelease-1", @changeSprint)
    sprintEntry.bind("KeyRelease-Up", @changeSprint)
    sprintEntry.bind("KeyRelease-Down", @changeSprint)

    @projectSprint = TkVariable.new
    @projectSprint.value = 0
    sprintEntry.textvariable = @projectSprint

    # Hours availble for current sprint
    @hoursAvailableVar = TkVariable.new
    hoursAvailable = TkEntry.new(@sprintTab) {width 5}
    hoursAvailable.textvariable = @hoursAvailableVar

    # Sprint's task tree
    @sprintTaskTree = Tk::Tile::Treeview.new(@sprintTab)

    columns = 'committer status'
    @project.sprintlength.times.each do |d|
      columns += " w#{d}"
    end

    @sprintTaskTree['columns'] = columns.to_s
    logger @sprintTaskTree['columns'], 4

    @sprintTaskTree.column_configure( 'committer', :width => 70, :anchor => 'center')
    @sprintTaskTree.heading_configure( 'committer', :text => 'Committer')
    @sprintTaskTree.heading_configure( 'status', :text => 'Status')

    @project.sprintlength.times.each do |d|
      @sprintTaskTree.heading_configure( "w#{d}", :text => DAYS[selectDay(d)])
      @sprintTaskTree.column_configure( "w#{d}", :width => 10, :anchor => 'center')
    end

    # Task edition fields
    @taskName = TkVariable.new
    @taskCommitter = TkVariable.new
    @taskStatus = TkVariable.new
    @taskDuration = Array.new
    @project.sprintlength.times.each  do |i|
      @taskDuration.push(TkVariable.new)
    end

    taskNameEntry = TkEntry.new(@sprintTab) {width 33}
    taskNameEntry.textvariable = @taskName

    taskCommitter = TkEntry.new(@sprintTab) #{width 10} #Tk::Tile::ComboBox.new(@sprintTab)
    taskCommitter.textvariable = @taskCommitter

    taskStatus = TkEntry.new(@sprintTab) #{width 15} #Tk::Tile::ComboBox.new(@sprintTab)
    taskStatus.textvariable = @taskStatus

    taskDurationEntry = Array.new
    @project.sprintlength.times.each do |i|
      taskDurationEntry.push(TkEntry.new(@sprintTab) do
        width 3
      end)
      taskDurationEntry[i].textvariable = @taskDuration[i]
    end

    procUpdateTask = Proc.new {
      item = @sprintTaskTree.focus_item()
      logger "procUpdateTask: " + item.inspect

      task = @project.findTask(item.to_i)

      updateTask(@sprintTaskTree.focus_item().to_i) if !item.nil?
      refreshView(task.task_id)
    }

    procDeleteTask = Proc.new {
      item = @sprintTaskTree.focus_item()
      logger "procUpdateTask: " + item.inspect
      if !item.nil?
        @project.deleteTask(item.to_i)
      end
      refreshView
    }


    procAddNewTask = Proc.new {
      logger "procAddNewTask: " + @taskName.inspect
      task = Task.new(@taskName.value, @taskCommitter.value, @taskStatus.value)
      @project.sprintlength.times.each  do |i|
        task.addDuration(i, @taskDuration[i].value.to_i)
        logger "task update w#{i}: " + task.duration[i].to_s
      end
      begin
        @project.addNewTaskToSprint(task)
      rescue ArgumentError
        Tk.messageBox(
            'type'    => "ok",
            'icon'    => "info",
            'title'   => "Title",
            'message' => "You have to give name to your task!"
          )
      end
      refreshView
    }

    procAddNewSubTask = Proc.new {
      task = Task.new(@taskName.value, @taskCommitter.value, @taskStatus.value)
      @project.sprintlength.times.each  do |i|
        task.addDuration(i, @taskDuration[i].value.to_i)
        logger "task update w#{i}: " + task.duration[i].to_s
      end
      begin
        parent_id = @sprintTaskTree.focus_item().to_i
        @project.addNewTaskToSprint(task, parent_id)
      rescue ArgumentError
        Tk.messageBox(
            'type'    => "ok",
            'icon'    => "info",
            'title'   => "Title",
            'message' => "You have to give name to your task!"
          )
      end
      refreshView
    }

    procMoveTaskUp = Proc.new {
      item = @sprintTaskTree.focus_item()
      logger "procMoveTaskUp: " + item.inspect
      if !item.nil?
        @project.moveTaskUp(item.to_i)
      end
      refreshView(item)
    }

    procMoveTaskDown = Proc.new {
      item = @sprintTaskTree.focus_item()
      logger "procMoveTaskDown: " + item.inspect
      if !item.nil?
        @project.moveTaskDown(item.to_i)
      end
      refreshView(item)
    }


    # Task update button
    copyButton = TkButton.new(@sprintTab) {
      text 'Copy open tasks'
      command( procUpdateTask )
    }

    # Task update button
    updateButton = TkButton.new(@sprintTab) {
      text 'Update Task'
      underline 0
      command( procUpdateTask )
    }

    # Task update button
    moveUpButton = TkButton.new(@sprintTab) {
      text 'Move up'
      command( procMoveTaskUp)
        }

    # Task update button
    moveDownButton = TkButton.new(@sprintTab) {
      text 'Move Down'
      command( procMoveTaskDown )
     }

    # Add new task button
    addNewTaskButton = TkButton.new(@sprintTab) {
      text 'Add new Task'
      underline 8
      command( procAddNewTask )
     }

   addNewSubTaskButton = TkButton.new(@sprintTab) {
      text 'Add Sub Task'
      underline 6
      command( procAddNewSubTask )
     }


    # Delete selected task button
    deleteButton = TkButton.new(@sprintTab) {
      text 'Delete Task'
      underline 0
      command( procDeleteTask )
     }

    @sprintTaskTree.grid(        :row => 0, :column => 0, :columnspan => numOfColumns, :rowspan => 10, :sticky => 'news' )
    TkGrid(TkLabel.new(@sprintTab, :text => "Select your sprint:"), :row => 1, :column => numOfColumns + 2, :sticky => 'ne')
    sprintEntry.grid(            :row => 1, :column => numOfColumns + 3, :columnspan => 2,:sticky => 'nw' )
    TkGrid(TkLabel.new(@sprintTab, :text => " "), :row => 1, :column => numOfColumns + 1)
    TkGrid(TkLabel.new(@sprintTab, :text => " "), :row => 0, :column => numOfColumns + 3)
    TkGrid(TkLabel.new(@sprintTab, :text => "Team velocity:"), :row => 2, :column => numOfColumns + 2, :sticky => 'ne')
    hoursAvailable.grid(         :row => 2, :column => numOfColumns + 3, :columnspan => 2, :sticky => 'nw' )
    copyButton.grid(             :row => 4, :column => numOfColumns + 2, :sticky => 'ne' )

    TkGrid(TkLabel.new(@sprintTab, :text => "Task name"), :row => 20, :column => 0)
    taskNameEntry.grid(                                   :row => 21, :column => 0, :sticky => 'news' )
    TkGrid(TkLabel.new(@sprintTab, :text => "Committer"), :row => 20, :column => 1)
    taskCommitter.grid(                                   :row => 21, :column => 1, :sticky => 'news' )
    TkGrid(TkLabel.new(@sprintTab, :text => "Status"),    :row => 20, :column => 2)
    taskStatus.grid(                                      :row => 21, :column => 2, :sticky => 'news' )

    TkGrid(TkLabel.new(@sprintTab, :text => 'Remaingin effort:'),  :row => 11, :column => 2)
    @project.sprintlength.times.each do |i|
      @effortsRemainingLabel.push(TkLabel.new(@sprintTab, :text => '0', :width => '3'))
      TkGrid(@effortsRemainingLabel[i],  :row => 11, :column => 3+i)
    end

    TkGrid(TkLabel.new(@sprintTab, :text => " "), :row => 12, :column => numOfColumns + 1)

    @project.sprintlength.times.each do |i|
      TkGrid(TkLabel.new(@sprintTab, :text => DAYS[selectDay(i)]),  :row => 20, :column => 3+i)
    end
    @project.sprintlength.times.each do |i|
      taskDurationEntry[i].grid(                          :row => 21, :column => 3+i, :sticky => 'news' )
    end

    updateButton.grid(           :row => 21, :column => numOfColumns + 2, :sticky => 'nw' )
    moveUpButton.grid(           :row => 21, :column => numOfColumns + 4, :sticky => 'nw' )
    moveDownButton.grid(         :row => 22, :column => numOfColumns + 4, :sticky => 'nw' )
    TkGrid(TkLabel.new(@sprintTab, :text => " "), :row => 23, :column => numOfColumns + 1)
    deleteButton.grid(           :row => 24, :column => numOfColumns + 4, :sticky => 'nw' )
    addNewTaskButton.grid(       :row => 22, :column => numOfColumns + 2, :sticky => 'nw' )
    addNewSubTaskButton.grid(    :row => 23, :column => numOfColumns + 2, :sticky => 'nw' )

    TkGrid(TkLabel.new(@sprintTab, :text => ""), :row => 10, :column => 0)

    # Keyboard binnigs
    @root.bind( "Control-u", procUpdateTask )
    @root.bind( "Control-t", procAddNewTask )
    @root.bind( "Control-b", procAddNewSubTask )
    @root.bind( "Control-d", procDeleteTask )

    @sprintTaskTree.bind("KeyRelease-Up", @changeTask)
    @sprintTaskTree.bind("KeyRelease-Down", @changeTask)
  end

  def createConfigTab(tab)
    @configsTab = TkFrame.new(tab)

    #project name
    nameEntry = TkEntry.new(@configsTab)
    @projectName = TkVariable.new
    @projectName.value = "Enter Project's name"
    nameEntry.textvariable = @projectName
    nameEntry.place('height' => 25,
            'width'  => 150,
            'x'      => 10,
            'y'      => 10)
  end

  def createMenu
    menu_click = Proc.new {
      Tk.messageBox(
        'type'    => "ok",
        'icon'    => "info",
        'title'   => "Title",
        'message' => "Not supported"
      )
    }

    save_click = Proc.new {
      saveClick
    }

    saveAs_click = Proc.new {
      saveAsProject
    }

    open_click = Proc.new {
      @controller.loadProject(Tk.getOpenFile(:filetypes => FILE_TYPES))
      @projectSprint.value = @project.sprint
      refreshView
    }

    new_click = Proc.new {
      newProject
    }

    exit_click = Proc.new {
      ret = false
      if @project.saved?
        exit
      else
          yes = Tk.messageBox(
          'type'    => "yesnocancel",
          'icon'    => "question",
          'title'   => "Title",
          'message' => "Project is not saved! Save before exiting?",
          'default' => "yes"
          )
        if yes == "yes"
          if @project.fileName.size > 0
            ret = @controller.saveProject
           else
             ret = saveAsProject
           end

          if ret
            exit
          end
        elsif yes == "no"
          exit
        end
      end
    }


    file_menu = TkMenu.new(@root)

    file_menu.add('command',
                  'label'     => "New...",
                  'command'   => new_click,
                  'underline' => 0)
    file_menu.add('command',
                  'label'     => "Open...",
                  'command'   => open_click,
                  'underline' => 0)
    file_menu.add('separator')
    file_menu.add('command',
                  'label'     => "Save",
                  'command'   => save_click,
                  'underline' => 0)
    file_menu.add('command',
                  'label'     => "Save As...",
                  'command'   => saveAs_click,
                  'underline' => 5)
    file_menu.add('separator')
    file_menu.add('command',
                  'label'     => "Exit",
                  'command'   => exit_click,
                  'underline' => 3)

    menu_bar = TkMenu.new
    menu_bar.add('cascade',
                'menu'  => file_menu,
                'label' => "File")

      # Keyboard shortcuts
    @root.bind( "Control-o", open_click )
    @root.bind( "Control-s", save_click )
    @root.bind( "Control-a", saveAs_click )
    @root.bind( "Control-n", new_click )
    @root.bind( "Control-x", exit_click )
    @root.protocol("WM_DELETE_WINDOW", exit_click)

    @root.menu(menu_bar)
  end

  def saveClick
    if @project.fileName.size > 0
      @controller.saveProject
    else
      saveAsProject
    end
  end

  def saveAsProject
    fileName = Tk.getSaveFile(:filetypes => FILE_TYPES )
    @controller.saveAsProject(fileName)
  end

  def newProject
    if !@project.saved?
      answer = Tk.messageBox(
        'type'    => "yesnocancel",
        'icon'    => "question",
        'title'   => "Title",
        'message' => "Creating new project but project is not saved! Save project or not. You can also cancel project creation.",
        'default' => "yes"
        )
      if answer == "yes"
        saveClick
      elsif answer == "cancel"
        return
      end
    end

    @project.clear
    refreshView
  end
end
