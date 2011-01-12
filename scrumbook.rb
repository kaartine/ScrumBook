require 'yaml'
require 'tk'
require 'tkextlib/tile'

require './project.rb'

require './helpfunctions.rb'

#export TCL_LIBRARY=/cygdrive/c/Tcl/lib/tcl8.4

class ScrumBook

  def initialize
    fileName = nil
    ARGV.each do|a|
      if File.exists?(a)
        fileName = a
      else
        Tk.messageBox(
	        'type'    => "ok",
	        'icon'    => "info",
	        'title'   => "Title",
	        'message' => "File \"#{a}\" doesn't exist!"
	      )
      end
    end

    @days = ['Mo', 'Tu', 'We', 'Th', 'Fr']
    @project = Project.new

    @root = TkRoot.new
    @root.title = "ScrumBook"

    createTabs
    createMenu

    loadProject(fileName) unless fileName.nil?
  end

  def createTabs
    tab = Tk::Tile::Notebook.new(@root) do
      width 1000
    end

    createConfigTab(tab)
    createSprintTab(tab)

    @burnDownTab = TkFrame.new(tab)

    tab.add @sprintTab, :text => 'Sprint'
    tab.add @burnDownTab, :text => 'Burn Down'
    tab.add @configsTab , :text => 'Configs'

    tab.pack("expand" => "1", "fill" => "both")
  end

  def refreshSprint(selected_item = nil)
    id = @projectSprint.value.to_i
    logger "sprint_id: " + id.to_s
    @project.sprint = id

    items = @sprintTaskTree.children('')
    @sprintTaskTree.delete(items)

    if @project.tasks[id]
      @project.tasks[id].each do |t|
        @sprintTaskTree.insert('', 'end', :id => t.name, :text => t.name, :tags => ['clickapple'])
        @sprintTaskTree.set( t.name, 'committer', t.committer)
        @sprintTaskTree.set( t.name, 'status', t.status)

        @project.sprintlength.times.each do |i|
          @sprintTaskTree.set(t.name, "w#{i}", t.duration[i])
        end

         @sprintTaskTree.tag_bind('clickapple', 'ButtonRelease-1', @changeTask);
      end
      @sprintTaskTree.selection_set(selected_item) if !selected_item.nil?

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

  def updateTask(item_name)
    logger "updateTask: " + item_name
    tasks = @project.getActiveSprintsTasks()
    id = tasks.index(item_name)
    logger "task id: " + id.to_s

    if !id.nil?
      tasks[id].name = @taskName.value
      tasks[id].committer = @taskCommitter.value
      tasks[id].status = @taskStatus.value
      @project.sprintlength.times.each  do |i|
        tasks[id].addDuration(i, @taskDuration[i].value.to_i)
        logger "task update w#{i}: " + tasks[id].duration[i].to_s
      end

      @project.not_saved = true
    end

    refreshSprint(tasks[id].name)
    refreshTaskEditor
  end

  def procUpdateTask
    item = @sprintTaskTree.focus_item()
    logger "procUpdateTask: " + item.inspect
    if @project.getActiveSprintsTasks().index(@taskName.value).nil?
      updateTask(@sprintTaskTree.focus_item().id) if !item.nil?
      refreshView
    else
      Tk.messageBox(
	        'type'    => "ok",
	        'icon'    => "info",
	        'title'   => "Title",
	        'message' => "Task #{@taskName.value} already exists!"
	      )
    end
  end

  def procDeleteTask
    item = @sprintTaskTree.focus_item()
    logger "procUpdateTask: " + item.inspect
    if !item.nil?
      @project.deleteTask(item.id)
    end
    refreshView
  end


  def procAddNewTask
    task = Task.new(@taskName.value, @taskCommitter.value, @taskStatus.value)
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
  end

  def procMoveTaskUp
    item = @sprintTaskTree.focus_item()
    logger "procMoveTaskUp: " + item.inspect
    if !item.nil?
      @project.moveTaskUp(item.id)
    end
    refreshView
    @sprintTaskTree.focus_item(item)
  end

  def procMoveTaskDown
    item = @sprintTaskTree.focus_item()
    logger "procMoveTaskDown: " + item.inspect
    if !item.nil?
      @project.moveTaskDown(item.id)
    end
    refreshView
    @sprintTaskTree.focus_item(item)
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
      command {$s.refreshSprint}
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

    logger columns
    @sprintTaskTree['columns'] = columns.to_s
    logger @sprintTaskTree['columns'], 4

    @sprintTaskTree.column_configure( 'committer', :width => 70, :anchor => 'center')
    @sprintTaskTree.heading_configure( 'committer', :text => 'Committer')
    @sprintTaskTree.heading_configure( 'status', :text => 'Status')
    logger @sprintTaskTree.inspect

    @project.sprintlength.times.each do |d|
      @sprintTaskTree.heading_configure( "w#{d}", :text => @days[selectDay(d)])
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

    # Task update button
    copyButton = TkButton.new(@sprintTab) {
      text 'Copy open tasks'
      command( proc {$s.procUpdateTask})
    }
    emptyLabel = TkLabel.new(@sprintTab)
    emptyLabel2 = TkLabel.new(@sprintTab)


    # Task update button
    updateButton = TkButton.new(@sprintTab) {
      text 'Update Task'
      command( proc {$s.procUpdateTask})
    }

    # Task update button
    moveUpButton = TkButton.new(@sprintTab) {
      text 'Move up'
      command( proc {$s.procMoveTaskUp})
        }
    # Task update button
    moveDownButton = TkButton.new(@sprintTab) {
      text 'Move Down'
      command( proc {$s.procMoveTaskDown})
     }

    # Add new task button
    addNewButton = TkButton.new(@sprintTab) {
      text 'Add new Task'
      command( proc {$s.procAddNewTask})
     }

    # Delete selected task button
    deleteButton = TkButton.new(@sprintTab) {
      text 'Delete Task'
      command( proc {$s.procDeleteTask})
     }

    @sprintTaskTree.grid(        :row => 0, :column => 0, :columnspan => numOfColumns, :rowspan => 10, :sticky => 'news' )
    TkGrid(TkLabel.new(@sprintTab, :text => "Select your sprint:"), :row => 1, :column => numOfColumns + 2, :sticky => 'new')
    sprintEntry.grid(            :row => 1, :column => numOfColumns + 3, :columnspan => 2,:sticky => 'new' )
    TkGrid(TkLabel.new(@sprintTab, :text => " "), :row => 1, :column => numOfColumns + 1)
    TkGrid(TkLabel.new(@sprintTab, :text => " "), :row => 0, :column => numOfColumns + 3)
    TkGrid(TkLabel.new(@sprintTab, :text => "Hours for Sprint:"), :row => 2, :column => numOfColumns + 2)
    hoursAvailable.grid(         :row => 2, :column => numOfColumns + 3, :columnspan => 2, :sticky => 'new' )
    copyButton.grid(             :row => 4, :column => numOfColumns + 2, :sticky => 'new' )

    TkGrid(TkLabel.new(@sprintTab, :text => "Task name"), :row => 20, :column => 0)
    taskNameEntry.grid(                                   :row => 21, :column => 0, :sticky => 'news' )
    TkGrid(TkLabel.new(@sprintTab, :text => "Committer"), :row => 20, :column => 1)
    taskCommitter.grid(                                   :row => 21, :column => 1, :sticky => 'news' )
    TkGrid(TkLabel.new(@sprintTab, :text => "Status"),    :row => 20, :column => 2)
    taskStatus.grid(                                      :row => 21, :column => 2, :sticky => 'news' )
    @project.sprintlength.times.each do |i|
      TkGrid(TkLabel.new(@sprintTab, :text => @days[selectDay(i)]),  :row => 20, :column => 3+i)
    end
    @project.sprintlength.times.each do |i|
      taskDurationEntry[i].grid(                          :row => 21, :column => 3+i, :sticky => 'news' )
    end

    updateButton.grid(           :row => 21, :column => numOfColumns + 2, :sticky => 'news' )
    moveUpButton.grid(           :row => 21, :column => numOfColumns + 4, :sticky => 'news' )
    moveDownButton.grid(         :row => 22, :column => numOfColumns + 4, :sticky => 'news' )
    TkGrid(TkLabel.new(@sprintTab, :text => " "), :row => 23, :column => numOfColumns + 1)
    deleteButton.grid(           :row => 24, :column => numOfColumns + 4, :sticky => 'news' )
    addNewButton.grid(           :row => 22, :column => numOfColumns + 2, :sticky => 'news' )

    TkGrid(TkLabel.new(@sprintTab, :text => ""), :row => 10, :column => 0)

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
    @menu_click = Proc.new {
      Tk.messageBox(
        'type'    => "ok",
        'icon'    => "info",
        'title'   => "Title",
        'message' => "Not supported"
      )
    }

    @save_click = Proc.new {
      saveClick
    }

    @saveAs_click = Proc.new {
      saveAsProject
    }


    @open_click = Proc.new {
      loadProject(Tk.getOpenFile)
    }

    @new_click = Proc.new {
      newProject
    }


    @exit = Proc.new {
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
                  'command'   => @new_click,
                  'underline' => 0)
    file_menu.add('command',
                  'label'     => "Open...",
                  'command'   => @open_click,
                  'underline' => 0)
    file_menu.add('command',
                  'label'     => "Close",
                  'command'   => @menu_click,
                  'underline' => 0)
    file_menu.add('separator')
    file_menu.add('command',
                  'label'     => "Save",
                  'command'   => @save_click,
                  'underline' => 0)
    file_menu.add('command',
                  'label'     => "Save As...",
                  'command'   => @saveAs_click,
                  'underline' => 5)
    file_menu.add('separator')
    file_menu.add('command',
                  'label'     => "Exit",
                  'command'   => @exit,
                  'underline' => 3)

    menu_bar = TkMenu.new
    menu_bar.add('cascade',
                'menu'  => file_menu,
                'label' => "File")

    @root.menu(menu_bar)

  end

  def saveClick
    if @project.fileName.size > 0
      saveProject
    else
      saveAsProject
    end
  end

  def saveAsProject
    fileName = Tk.getSaveFile
    if fileName.size > 0
    	@project.fileName=fileName
    	logger "SaveAs fileName:" + fileName
    	saveProject
    end
  end

  def saveProject
    file = File.new @project.fileName, 'w'
    @project.not_saved = false
    logger @project.inspect
    serial = YAML.dump( @project )
    logger "serial: " + serial.inspect, 4
    file.write serial
    file.close
    true
  end

  def loadProject(fileName)
    file = File.new fileName, 'r'
    serial = file.read
    file.close
    @project = YAML.load( serial )
    logger @project.inspect

    logger "serial: " + serial.inspect, 4

    @projectSprint.value = @project.sprint
    @project.fileName = fileName

    refreshView
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

    @project = Project.new
    refreshView
  end


  def refreshView
    refreshSprint
    refreshTaskEditor
  end
end

$s = ScrumBook.new
Tk.mainloop