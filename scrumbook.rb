require 'tk'
require 'tkextlib/tile'

require './project.rb'

require './helpfunctions.rb'

#export TCL_LIBRARY=/cygdrive/c/Tcl/lib/tcl8.4

class ScrumBook

  def initialize
    @days = ['ma', 'ti', 'ke', 'to', 'pe']
    @project = Project.new

    @root = TkRoot.new
    @root.title = "ScrumBook"

    createTabs
    createMenu
  end

  def createTabs
    tab = Tk::Tile::Notebook.new(@root) do
      width 1000
    end

    createConfigTab(tab)
    createSprintTab(tab)

    @burnDownTab = TkFrame.new(tab)

    tab.add @configsTab , :text => 'Configs'
    tab.add @sprintTab, :text => 'Sprint'
    tab.add @burnDownTab, :text => 'Burn Down'

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

        @project.sprintlength.to_i.times.each do |i|
          @sprintTaskTree.set(t.name, "w#{i}", t.duration[i])
        end

         @sprintTaskTree.tag_bind('clickapple', 'ButtonRelease-1', @changeTask);
      end
      @sprintTaskTree.selection_set(selected_item) if !selected_item.nil?

      logger "project: " + @project.inspect
    end

#    @sprintTaskTree.insert('', 'end', :id => 'widgets', :text => 'Widget Tour')
#    @sprintTaskTree.insert('', 0, :id => 'gallery', :text => 'Applications')
#    item = @sprintTaskTree.insert('', 'end', :text => 'Tutorial')
#    @sprintTaskTree.insert( 'widgets', 'end', :text => 'Canvas')
#    @sprintTaskTree.insert( item, 'end', :text => 'Tree')
#    @sprintTaskTree.set('widgets', 'committer', 'JK'); # or item.set('size', '12KB')
#    size = @sprintTaskTree.get('widgets', 'committer');  # or item.get('size')
#    @sprintTaskTree.insert('', 'end', :text => 'Listbox', :values => ['GK','Done','0'])

#    @sprintTaskTree.itemconfigure('widgets', 'open', true); # or item['open'] = true
#    isopen = @sprintTaskTree.itemcget('widgets', 'open');   # or isopen = item['open']

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
      @project.sprintlength.to_i.times.each  do |i|
        @taskDuration[i].value = tasks[id].duration[i]
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
      @project.sprintlength.to_i.times.each  do |i|
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
    updateTask(@sprintTaskTree.focus_item().id) if !item.nil?
  end

  def procAddNewTask
    task = Task.new(@taskName.value, @taskCommitter.value, @taskStatus.value)
    @project.sprintlength.to_i.times.each  do |i|
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


  def createSprintTab(tab)
	  @sprintTab = Tk::Tile::Frame.new(@sprintTab) {padding "3 3 12 12"}.grid(:sticky => 'nws')
		TkGrid.columnconfigure @sprintTab, 0, :weight => 1
		TkGrid.rowconfigure @sprintTab, 0, :weight => 1

    @changeSprint = Proc.new {
      refreshSprint
    }

    @changeTask = Proc.new {
      refreshTaskEditor
    }

    #sprint selector
    sprintLabelVar = TkVariable.new
		sprintLabel = TkLabel.new(@sprintTab) do
		  textvariable
		  borderwidth 5
#		  font TkFont.new('times 20 bold')
	#	  foreground  "red"
		#  relief      "groove"
		  #pack("side" => "right",  "padx"=> "50", "pady"=> "50")
		  grid( :column => 0, :row => 0, :sticky => 'wn') #.pack("side" => "left")
		end

		sprintLabel['textvariable'] = sprintLabelVar
		sprintLabelVar.value = 'Select your sprint:'

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
    sprintEntry.grid( :column => 0, :row => 0, :sticky => 'wn',  "padx"=> "3", "pady"=> "30") #.pack("side" => "left")

		# Sprint's task tree
    @sprintTaskTree = Tk::Tile::Treeview.new(@sprintTab)

    columns = 'committer status'
    @project.sprintlength.to_i.times.each do |d|
      columns += " w#{d}"
    end

    logger columns
    @sprintTaskTree['columns'] = columns.to_s
    logger @sprintTaskTree['columns'], 4

    @sprintTaskTree.column_configure( 'committer', :width => 70, :anchor => 'center')
    @sprintTaskTree.heading_configure( 'committer', :text => 'Committer')
    @sprintTaskTree.heading_configure( 'status', :text => 'Status')

    i = 0
    @project.sprintlength.to_i.times.each do |d|
      @sprintTaskTree.heading_configure( "w#{d}", :text => @days[i])
      @sprintTaskTree.column_configure( "w#{d}", :width => 10, :anchor => 'center')
      i+=1
      if i >= 5
         i = 0
      end
      logger i, 4
    end

    @sprintTaskTree.grid( :column => 1, :row => 0, :sticky => 'news' ) #.pack("side" => "top")

    refreshSprint

    # Task edition fields
    content = Tk::Tile::Frame.new(@sprintTab) {padding "0 0 0 0"}.grid(:column => 1, :row => 1, :sticky => 'news')

    @taskName = TkVariable.new
    @taskCommitter = TkVariable.new
    @taskStatus = TkVariable.new
    @taskDuration = Array.new
    @project.sprintlength.to_i.times.each  do |i|
      @taskDuration << TkVariable.new
    end

    taskNameEntry = TkEntry.new(content) {width 33}
    taskNameEntry.textvariable = @taskName
    taskNameEntry.grid( :column => 0, :row => 0, :sticky => 'news' ) #.pack("side" => "top") #pack("side" => "left")

    taskCommitter = TkEntry.new(content) {width 10} #Tk::Tile::ComboBox.new(@sprintTab)
    taskCommitter.textvariable = @taskCommitter
    taskCommitter.grid( :column => 1, :row => 0, :sticky => 'news' ) #.pack("side" => "left")

    taskStatus = TkEntry.new(content) {width 15} #Tk::Tile::ComboBox.new(@sprintTab)
    taskStatus.textvariable = @taskStatus
    taskStatus.grid( :column => 2, :row => 0, :sticky => 'news' ) #.pack("side" => "left")

    taskDurationEntry = Array.new
    @project.sprintlength.to_i.times.each do |i|
      taskDurationEntry.push(TkEntry.new(content) do
        width 3
      end)
      taskDurationEntry[i].textvariable = @taskDuration[i]
      taskDurationEntry[i].grid( :column => 3+i, :row => 0, :sticky => 'news' ) #.pack("side" => "left")
    end

    # Task update button
    TkButton.new(content) {
      text 'Update Task'
      command( proc {$s.procUpdateTask})
      #pack "side" => "left"
    }.grid( :column => 0, :row => 1, :sticky => 'news' ) #

    # Add new task button
    TkButton.new(content) {
      text 'Add new Task'
      command( proc {$s.procAddNewTask})
      #pack "side" => "left"
    }.grid( :column => 1, :row => 1, :sticky => 'news' ) #

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
      if @project.fileName.size > 0
        saveProject
      else
        saveAsProject
      end
    }

    @saveAs_click = Proc.new {
      saveAsProject
    }


    @open_click = Proc.new {
      loadProject
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
                  'command'   => @menu_click,
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
    @project.not_saved = true
    logger @project.inspect
    serial = Marshal.dump( @project )
    logger "serial: " + serial.inspect, 4
    file.write serial
    file.close
    true
  end

  def loadProject
    fileName = Tk.getOpenFile
    file = File.new fileName, 'r'
    serial = file.read
    file.close
    @project = Marshal.load( serial )
    logger @project.inspect

    logger "serial: " + serial.inspect, 4

    @projectSprint.value = @project.sprint

    refreshView
  end


  def refreshView
    refreshSprint
    refreshTaskEditor
  end
end

$s = ScrumBook.new
Tk.mainloop