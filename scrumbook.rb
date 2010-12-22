require 'tk'
require 'tkextlib/tile'

require './project.rb'

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
    	height 200
    	width 800
    end

    createConfigTab(tab)
    createSprintTab(tab)

    @burnDownTab = TkFrame.new(tab)

    tab.add @configsTab , :text => 'Configs'
    tab.add @sprintTab, :text => 'Sprint'
    tab.add @burnDownTab, :text => 'Burn Down'

    tab.pack
  end

	def createSprintTab(tab)
		@sprintTab = TkFrame.new(tab)

		tree = Tk::Tile::Treeview.new(@sprintTab) # {columns 'commiter status'}

		print @project.sprintlength.value.to_i
		columns = 'committer status'
		@project.sprintlength.value.to_i.times.each do |d|
			columns += " w" + d.to_s()
		end
		print columns
	  tree['columns'] = columns.to_s
		print tree['columns']

		tree.insert('', 'end', :id => 'widgets', :text => 'Widget Tour')
		tree.insert('', 0, :id => 'gallery', :text => 'Applications')
		item = tree.insert('', 'end', :text => 'Tutorial')
		tree.insert( 'widgets', 'end', :text => 'Canvas')
		tree.insert( item, 'end', :text => 'Tree')

		tree.itemconfigure('widgets', 'open', true); # or item['open'] = true
		isopen = tree.itemcget('widgets', 'open');   # or isopen = item['open']

		tree.column_configure( 'committer', :width => 90, :anchor => 'center')
		tree.heading_configure( 'committer', :text => 'Committer')
		tree.heading_configure( 'status', :text => 'Status')

		i = 0
		@project.sprintlength.value.to_i.times.each do |d|
			tree.heading_configure( 'w' + d.to_s, :text => @days[i])
			tree.column_configure( 'w' + d.to_s, :width => 10, :anchor => 'center')
			i+=1
			if i >= 5
			 	i = 0
			end
			print i
		end

		tree.set('widgets', 'committer', 'JK'); # or item.set('size', '12KB')
		size = tree.get('widgets', 'committer');  # or item.get('size')
		tree.insert('', 'end', :text => 'Listbox', :values => ['GK','Done','0'])

		tree.pack
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

		#sprint lenght
		sprintEntry = TkEntry.new(@configsTab)
		@project.sprintlength = TkVariable.new
		@project.sprintlength.value = "10"
		sprintEntry.textvariable = @project.sprintlength
		sprintEntry.place('height' => 25,
            'width'  => 150,
            'x'      => 200,
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

ScrumBook.new
Tk.mainloop