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

require './configurations'
require './helpfunctions.rb'

class GuiManager

  attr_accessor :project

  def initialize(project)

    @project = project
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
    @projectSprint.value = @project.sprint

    id = @projectSprint.value.to_i
    logger "sprint_id: " + id.to_s
    @project.sprint = id

    items = @sprintTaskTree.children('')
    @sprintTaskTree.delete(items)

    use_as_selected = selected_item
    temp = nil?
    if @project.tasks[id]
      @project.tasks[id].each do |t|
        temp = @sprintTaskTree.insert('', 'end', :id => t.name, :text => t.name, :tags => ['clickapple'])
        @sprintTaskTree.set( t.name, 'committer', t.committer)
        @sprintTaskTree.set( t.name, 'status', t.status)

        @project.sprintlength.times.each do |i|
          @sprintTaskTree.set(t.name, "w#{i}", t.duration[i])
        end

        @sprintTaskTree.tag_bind('clickapple', 'ButtonRelease-1', @changeTask);

        if( selected_item == t.name )
          use_as_selected = temp
          logger "found new selection: " + temp.inspect
        end
      end

      @sprintTaskTree.focus_item(use_as_selected)

      logger "project: " + @project.inspect
    end
  end

  def refreshTaskEditor
    item = @sprintTaskTree.focus_item()
    logger "selected: " + item.inspect

    if !item.nil?
      tasks = @project.getActiveSprintsTasks()
      id = tasks.index(item.id.to_s)

      logger "task id: " + id.to_s
      logger tasks[id].inspect

      @taskName.value = tasks[id].name
      @taskCommitter.value = tasks[id].committer
      @taskStatus.value = tasks[id].status
      @project.sprintlength.times.each  do |i|
        @taskDuration[i].value = tasks[id].duration[i]
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

  private

  def createTabs
    tab = Tk::Tile::Notebook.new(@root) do
      width 1000
      height 600
    end

    createConfigTab(tab)
    createSprintTab(tab)

    @burnDownTab = TkFrame.new(tab)

    tab.add @sprintTab, :text => 'Sprint'
    tab.add @burnDownTab, :text => 'Burn Down'
    tab.add @configsTab , :text => 'Configs'

    tab.pack("expand" => "1", "fill" => "both")
  end

  def updateTask(item_name)
    logger "updateTask: " + item_name
    tasks = @project.getActiveSprintsTasks()
    id = tasks.index(item_name)
    logger "task id: " + id.to_s

    if !id.nil?
      tasks[id].project = @project
      tasks[id].name = @taskName.value
      tasks[id].committer = @taskCommitter.value
      tasks[id].status = @taskStatus.value
      @project.sprintlength.times.each  do |i|
        tasks[id].addDuration(i, @taskDuration[i].value.to_i)
        logger "task update w#{i}: " + tasks[id].duration[i].to_s
      end
    end
  end

  def createSprintTab(tab)
    @sprintTab = Tk::Tile::Frame.new(@sprintTab) {padding "3 3 12 12"}.grid(:sticky => 'nws')
    TkGrid.columnconfigure( @sprintTab, 0, :weight => 1 )
    TkGrid.rowconfigure( @sprintTab, 0, :weight => 1 )

    @changeSprint = Proc.new {
      refreshSprint
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
      command {$s.refreshView}
    }
    sprintEntry.bind("ButtonRelease-1", @changeSprint)

    @projectSprint = TkVariable.new
    @projectSprint.value = "0"
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
    logger @sprintTaskTree.inspect

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

      tasks = @project.getActiveSprintsTasks()
      index = tasks.index(item.id)
      if tasks[index].name == @taskName.value || tasks.index(@taskName.value).nil?
        updateTask(@sprintTaskTree.focus_item().id) if !item.nil?
        refreshView(tasks[index].name)
      else
        Tk.messageBox(
            'type'    => "ok",
            'icon'    => "info",
            'title'   => "Title",
            'message' => "Task \"#{@taskName.value}\" already exists!"
          )
      end
    }

    procDeleteTask = Proc.new {
      item = @sprintTaskTree.focus_item()
      logger "procUpdateTask: " + item.inspect
      if !item.nil?
        @project.deleteTask(item.id)
      end
      refreshView
    }


    procAddNewTask = Proc.new {
      task = Task.new(@taskName.value, @taskCommitter.value, @taskStatus.value, @project)
      @project.sprintlength.times.each  do |i|
        task.addDuration(i, @taskDuration[i].value.to_i)
        logger "task update w#{i}: " + task.duration[i].to_s
      end
      begin
        if @project.addNewTaskToSprint(task).nil?
          Tk.messageBox(
            'type'    => "ok",
            'icon'    => "info",
            'title'   => "Title",
            'message' => "Task #{@taskName.value} already exists!"
          )
        end
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
        @project.moveTaskUp(item.id)
      end
      refreshView(item)
    }

    procMoveTaskDown = Proc.new {
      item = @sprintTaskTree.focus_item()
      logger "procMoveTaskDown: " + item.inspect
      if !item.nil?
        @project.moveTaskDown(item.id)
      end
      refreshView(item)
    }


    # Task update button
    copyButton = TkButton.new(@sprintTab) {
      text 'Copy open tasks'
      command( procUpdateTask )
    }
    emptyLabel = TkLabel.new(@sprintTab)
    emptyLabel2 = TkLabel.new(@sprintTab)


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
    addNewButton = TkButton.new(@sprintTab) {
      text 'Add new Task'
      underline 8
      command( procAddNewTask )
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
    addNewButton.grid(           :row => 22, :column => numOfColumns + 2, :sticky => 'nw' )

    TkGrid(TkLabel.new(@sprintTab, :text => ""), :row => 10, :column => 0)

    @root.bind( "Control-u", procUpdateTask )
    @root.bind( "Control-t", procAddNewTask )
    @root.bind( "Control-d", procDeleteTask )

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
            ret = saveProject
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
    @root.bind( "Control-s", save_click )
    @root.bind( "Control-o", open_click )
    @root.bind( "Control-a", saveAs_click )
    @root.bind( "Control-n", new_click )
    @root.bind( "Control-x", exit_click )

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
    @controller.saveProject
  end

  def newProject
    if !@project.saved?
      answer = Tk.messageBox(
        'type'    => "yesnocancel",
        'icon'    => "question",
        'title'   => "Title",
        'message' => "Creating new project but project is not saved! Save project or not. You can also calcel project creation.",
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