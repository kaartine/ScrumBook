require 'tk'
require 'tkextlib/tile'

require './project.rb'

#export TCL_LIBRARY=/cygdrive/c/Tcl/lib/tcl8.4


class ScrumBook

  def initialize
  	@project = Project.new

    @root = TkRoot.new
    @root.title = "ScrumBook"

    createTabs

    createMenu
  end

  def createTabs
    tab = Tk::Tile::Notebook.new(@root) do
    	height 200
    	width 400
    end

    createConfigTab(tab)

    @sprintTab = TkFrame.new(tab)
    @burnDownTab = TkFrame.new(tab)

    tab.add @configsTab , :text => 'Configs'
    tab.add @sprintTab, :text => 'Sprint'
    tab.add @burnDownTab, :text => 'Burn Down'

    tab.pack
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
		@project.sprintlength.value = "Sprint length in days"
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
                  'command'   => @menu_click,
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