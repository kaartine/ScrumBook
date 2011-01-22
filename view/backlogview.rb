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

module BacklogView

  def create_backlog_tab(tab)
    @backlog_tab = Tk::Tile::Frame.new(tab) {padding "3 3 12 12"}.grid(:sticky => 'nws')
    TkGrid.columnconfigure( @backlog_tab, 0, :weight => 1 )
    TkGrid.rowconfigure( @backlog_tab, 0, :weight => 1 )


    # Backlog tree
    @backlog_tree = Tk::Tile::Treeview.new(@backlog_tab)

    columns = 'estimate milestone sprint'

    @backlog_tree['columns'] = columns.to_s

    @backlog_tree.column_configure( '#0', :width => 400, :anchor => 'center')
    @backlog_tree.heading_configure( 'estimate', :text => ESTIMATE)
    @backlog_tree.column_configure( 'estimate', :width => 60, :anchor => 'center')
    @backlog_tree.heading_configure( 'milestone', :text => MILESTONE)
    @backlog_tree.column_configure( 'milestone', :width => 60, :anchor => 'center')
    @backlog_tree.heading_configure( 'sprint', :text => START_SPRINT)
    @backlog_tree.column_configure( 'sprint', :width => 60, :anchor => 'center')

    @proc_update_backlog_item = Proc.new {
      item = @backlog_tree.focus_item()
      logger "proc_update_backlog_item: " + item.inspect

      task = @project.findTask(item.to_i)

      updateTask(@backlog_tree.focus_item().to_i) if !item.nil?
      refreshView(task.task_id)
    }

    @proc_add_new_backlog_item = Proc.new {
      logger "proc_add_new_backlog_item: " + @taskName.inspect
      task = Task.new(@taskName.value, '', NEW_STATUS)
      task.milestone = @task_milestone
      task.estimate = @task_estimate
      begin
        @project.add_new_task_to_backlog(task)
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

    # Task update button
    updateButton = TkButton.new(@backlog_tab) {
      text 'Update Task'
      underline 0
      command( @proc_update_backlog_item )
    }

    # Task update button
    moveUpButton = TkButton.new(@backlog_tab) {
      text 'Move up'
      command( @procMoveTaskUp)
        }

    # Task update button
    moveDownButton = TkButton.new(@backlog_tab) {
      text 'Move Down'
      command( @procMoveTaskDown )
     }

    # Add new task button
    addNewTaskButton = TkButton.new(@backlog_tab) {
      text 'Add new Task'
      underline 8
      command( @proc_add_new_backlog_item )
     }

    # Delete selected task button
    deleteButton = TkButton.new(@backlog_tab) {
      text 'Delete Task'
      underline 0
      command( @procDeleteTask )
     }

    # Task edition fields
    @task_milestone = TkVariable.new
    @task_effort = TkVariable.new
    @task_for_sprint = Array.new

    task_name_entry = TkEntry.new(@backlog_tab)
    task_name_entry.textvariable = @taskName

    task_milestone_entry = TkEntry.new(@backlog_tab)
    task_milestone_entry.textvariable = @task_milestone

    task_estimate_entry = TkEntry.new(@backlog_tab)
    task_estimate_entry.textvariable = @task_effort

    task_for_sprint_entry = TkEntry.new(@backlog_tab)
    task_for_sprint_entry.textvariable = @task_for_sprint

    task_comment = TkText.new(@backlog_tab) do
      width 30
      height 5
      borderwidth 1
    #  font TkFont.new('times 12 bold')
    end

    @backlog_tree.grid(        :row => 0, :column => 0, :columnspan => 4, :rowspan => 10, :sticky => 'news' )

    TkGrid(TkLabel.new(@backlog_tab, :text => TASK_NAME), :row => 20, :column => 0)
    task_name_entry.grid(                                 :row => 21, :column => 0, :sticky => 'news' )
    TkGrid(TkLabel.new(@backlog_tab, :text => MILESTONE), :row => 20, :column => 1)
    task_milestone_entry.grid(                            :row => 21, :column => 1, :sticky => 'news' )
    TkGrid(TkLabel.new(@backlog_tab, :text => ESTIMATE), :row => 20, :column => 2)
    task_estimate_entry.grid(                             :row => 21, :column => 2, :sticky => 'news' )
    TkGrid(TkLabel.new(@backlog_tab, :text => START_SPRINT), :row => 20, :column => 3)
    task_for_sprint_entry.grid(                              :row => 21, :column => 3, :sticky => 'news' )

    updateButton.grid(           :row => 21, :column => numOfColumns + 2, :sticky => 'nw' )
    moveUpButton.grid(           :row => 21, :column => numOfColumns + 4, :sticky => 'nw' )
    moveDownButton.grid(         :row => 22, :column => numOfColumns + 4, :sticky => 'nw' )
    TkGrid(TkLabel.new(@backlog_tab, :text => " "), :row => 23, :column => numOfColumns + 1)
    deleteButton.grid(           :row => 24, :column => numOfColumns + 4, :sticky => 'nw' )
    addNewTaskButton.grid(       :row => 22, :column => numOfColumns + 2, :sticky => 'nw' )

    TkGrid(TkLabel.new(@backlog_tab, :text => COMMENT), :row => 23, :column => 0)
    task_comment.grid(           :row => 24, :column => 0, :columnspan => 2, :sticky => 'news')

  end
end