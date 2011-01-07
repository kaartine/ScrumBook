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
    	width 800
    end

    createConfigTab(tab)
    createSprintTab(tab)

    @burnDownTab = TkFrame.new(tab)

    tab.add @configsTab , :text => 'Configs'
    tab.add @sprintTab, :text => 'Sprint'
    tab.add @burnDownTab, :text => 'Burn Down'

    tab.pack("expand" => "1", "fill" => "both")
  end

  def updateSprint(selected_item = nil)
  	id = @project.sprint.value.to_i
  	logger "sprint_id: " + id.to_s

		items = @sprintTaskTree.children('')
  	@sprintTaskTree.delete(items)

		if @project.tasks[id]
	  	@project.tasks[id].each do |t|
	  		@sprintTaskTree.insert('', 'end', :id => t.name, :text => t.name, :tags => ['clickapple'])
	  		@sprintTaskTree.set( t.name, 'committer', t.committer)
	  		@sprintTaskTree.set( t.name, 'status', t.status)

 				@sprintTaskTree.tag_bind('clickapple', 'ButtonRelease-1', @changeTask);
	  	end
	  	@sprintTaskTree.selection_set(selected_item) if !selected_item.nil?
	  end

#		@sprintTaskTree.insert('', 'end', :id => 'widgets', :text => 'Widget Tour')
#		@sprintTaskTree.insert('', 0, :id => 'gallery', :text => 'Applications')
#		item = @sprintTaskTree.insert('', 'end', :text => 'Tutorial')
#		@sprintTaskTree.insert( 'widgets', 'end', :text => 'Canvas')
#		@sprintTaskTree.insert( item, 'end', :text => 'Tree')
#		@sprintTaskTree.set('widgets', 'committer', 'JK'); # or item.set('size', '12KB')
#		size = @sprintTaskTree.get('widgets', 'committer');  # or item.get('size')
#		@sprintTaskTree.insert('', 'end', :text => 'Listbox', :values => ['GK','Done','0'])

#		@sprintTaskTree.itemconfigure('widgets', 'open', true); # or item['open'] = true
#		isopen = @sprintTaskTree.itemcget('widgets', 'open');   # or isopen = item['open']

  end

  def updateTaskEditor
		item = @sprintTaskTree.focus_item()
		logger "selected: " + item.inspect

		if !item.nil?
			@taskName.value = item.id
			@taskCommitter.value = @sprintTaskTree.get(item, 'committer')
			@taskStatus.value = @sprintTaskTree.get(item, 'status')
			@project.sprintlength.to_i.times.each  do |i|
				@taskDuration[i].value = @sprintTaskTree.get(item, "w#{i}")
			end
		end
	end

	def updateTask(id)
		logger "updateTask: " + id.to_s

		tasks = @project.getActiveSprintsTasks()
		id = tasks.index(id)
		logger "task id: " + id.to_s

		if !id.nil?
			tasks[id].name = @taskName.value
			tasks[id].committer = @taskCommitter.value
			tasks[id].status = @taskStatus.value
			@project.sprintlength.to_i.times.each  do |i|
				tasks[id].duration[i] = @taskDuration[i].value
			end
		end

		updateSprint(tasks[id].name)

	end

	def procUpdateTask
		item = @sprintTaskTree.focus_item()
		updateTask(@sprintTaskTree.focus_item().id) if !item.nil?
	end

	def createSprintTab(tab)
		@sprintTab = TkFrame.new(tab)

		@changeSprint = Proc.new {
			updateSprint
		}

		@changeTask = Proc.new {
			updateTaskEditor
		}

		#sprint selector
		sprintEntry = TkSpinbox.new(@sprintTab) do
			to 1000
			from 0
			increment 1
			width 10
			command {$s.updateSprint}
		end

		sprintEntry.bind("ButtonRelease-1", @changeSprint)

		@project.sprint = TkVariable.new
		@project.sprint.value = "1"
		sprintEntry.textvariable = @project.sprint
		sprintEntry.pack("side" => "left")

		@sprintTaskTree = Tk::Tile::Treeview.new(@sprintTab)

		columns = 'committer status'
		@project.sprintlength.to_i.times.each do |d|
			columns += " w" + d.to_s()
		end

		logger columns
	  @sprintTaskTree['columns'] = columns.to_s
		logger @sprintTaskTree['columns'], 4

		@sprintTaskTree.column_configure( 'committer', :width => 90, :anchor => 'center')
		@sprintTaskTree.heading_configure( 'committer', :text => 'Committer')
		@sprintTaskTree.heading_configure( 'status', :text => 'Status')

		i = 0
		@project.sprintlength.to_i.times.each do |d|
			@sprintTaskTree.heading_configure( 'w' + d.to_s, :text => @days[i])
			@sprintTaskTree.column_configure( 'w' + d.to_s, :width => 10, :anchor => 'center')
			i+=1
			if i >= 5
			 	i = 0
			end
			logger i, 4
		end

		@sprintTaskTree.pack("side" => "top")

		@taskName = TkVariable.new
		@taskCommitter = TkVariable.new
		@taskStatus = TkVariable.new
		@taskDuration = Array.new
		@project.sprintlength.to_i.times.each  do |i|
			@taskDuration << TkVariable.new
		end

		updateSprint

		taskNameEntry = TkEntry.new(@sprintTab)
		taskNameEntry.textvariable = @taskName
		taskNameEntry.pack("side" => "left")

		taskCommitter = TkEntry.new(@sprintTab) #Tk::Tile::ComboBox.new(@sprintTab)
		taskCommitter.textvariable = @taskCommitter
		taskCommitter.pack("side" => "left")

		taskStatus = TkEntry.new(@sprintTab) #Tk::Tile::ComboBox.new(@sprintTab)
		taskStatus.textvariable = @taskStatus
		taskStatus.pack("side" => "left")
		taskDurationEntry = Array.new
		@project.sprintlength.to_i.times.each do |i|
			taskDurationEntry << TkEntry.new(@sprintTab) do
				width 2
			end
			taskDurationEntry[i].pack("side" => "left")
		end

		TkButton.new(@sprintTab) do
			text 'Update Task'
			command( proc {$s.procUpdateTask})
			pack "side" => "left"
		end

	end

  def createConfigTab(tab)
		@configsTab = TkFrame.new(tab)

		#project name
		nameEntry = TkEntry.new(@configsTab)
		@project.name = TkVariable.new
		@project.name.value = "Enter Project's name"
		nameEntry.textvariable = @project.name
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

    @exit = Proc.new {
    	if @project.saved?
      	exit
      else
     		 yes = Tk.messageBox(
	        'type'    => "yesno",
	        'icon'    => "question",
	        'title'   => "Title",
	        'message' => "Project is not saved! Save before exiting?",
	        'default' => "yes"
      		)
      	if yes == "yes"
      		@project.save
      	end

      	exit
      end
    }


    file_menu = TkMenu.new(@root)

    file_menu.add('command',
                  'label'     => "New...",
                  'command'   => @menu_click,
                  'underline' => 0)
    file_menu.add('command',
                  'label'     => "Open...",
                  'command'   => @menu_click,
                  'underline' => 0)
    file_menu.add('command',
                  'label'     => "Close",
                  'command'   => @menu_click,
                  'underline' => 0)
    file_menu.add('separator')
    file_menu.add('command',
                  'label'     => "Save",
                  'command'   => @menu_click,
                  'underline' => 0)
    file_menu.add('command',
                  'label'     => "Save As...",
                  'command'   => @menu_click,
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

end

$s = ScrumBook.new
Tk.mainloop