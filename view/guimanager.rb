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

require './lib/configurations'
require './lib/helpfunctions'
require './view/backlogview'
require './view/burndownview'
require './view/sprintview'

class GuiManager

  include BurnDownView

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
    @selected_tab.refreshView(selected_item)
  end

  def refreshTitle
    new_title = TITLE
    new_title += ' *' unless @project.saved?
    @root.title = new_title
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

  def update_project
    @project = Project.create

    @views.each do |view|
      view.update_project
    end
  end


  private

  def createTabs
    @tab = Tk::Tile::Notebook.new(@root) do
      width WIDTH
      height HEIGHT
    end

    $tab_c = @tab

    @views = Array.new

    # TODO: change these to classes
    createConfigTab(@tab)
    createBurnDownTab(@tab)

    @sprintTab = SprintView.new(self, @tab)
    @backlog_tab = BacklogView.new(self, @tab)
    @views.push(@backlog_tab)
    @views.push(@sprintTab)

    tab_changed = Proc.new {
      logger "selected tab: #{@tab.selected}"
      @selected_tab = @tab.selected

      # Upadate keyboard binnigs
      @selected_tab.bind_shortcuts(@root)
      @selected_tab.refreshView
    }

    @tab.bind("<NotebookTabChanged>", tab_changed)

    @tab.add @sprintTab, :text => 'Sprint'
    @tab.add @backlog_tab, :text => 'Backlog'
    @tab.add @burnDownTab, :text => 'Burn Down'
    @tab.add @configsTab , :text => 'Configs'

    @tab.pack("expand" => "1", "fill" => "both")
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
