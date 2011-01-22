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

module BurnDownView

  def createBurnDownTab(tab)
    @burnDownTab = TkCanvas.new(tab)

    @sprintWidth = (WIDTH - 20) / @project.sprintlength
    @sprintHeight = (HEIGHT - 20)
    @sprintStartX = 10
    @sprintStartY = 10

    @sprintEndX   = 10 + @project.sprintlength*@sprintWidth
    @sprintEndY   = 10 + @sprintHeight
    @sprintMidleX = 5
    @sprintMidleY = 5

    TkcRectangle.new(@burnDownTab, 10,  10,    WIDTH-10,  HEIGHT-10,
                         'width' => 1)

    # day separators
    @project.sprintlength.times do |i|
      TkcLine.new(@burnDownTab, @sprintStartX+i*@sprintWidth, HEIGHT-30, @sprintStartX+i*@sprintWidth, HEIGHT-20)
      TkLabel.new(@burnDownTab, :text => i).place( 'relx' => @sprintMidleX+i*@sprintMidleX, 'rely' => HEIGHT-30)
    end

    # Velocity
    TkcLine.new(@burnDownTab, @sprintStartX+@sprintMidleX, @sprintStartY+@sprintMidleY,
                              @sprintEndX-@sprintMidleX, @sprintHeight-@sprintMidleY)

  end
end