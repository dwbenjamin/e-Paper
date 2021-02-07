require 'set'

# *****************************************************************************
# * | File        :	  epd2in9_V2.py
# * | Author      :   Waveshare team
# * | Function    :   Electronic paper driver
# * | Info        :
# *----------------
# * | This version:   V1.0
# * | Date        :   2020-10-20
# # | Info        :   python demo
# -----------------------------------------------------------------------------
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documnetation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to  whom the Software is
# furished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS OR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

import logging
from . import epdconfig

# Display resolution
EPD_WIDTH       = 128
EPD_HEIGHT      = 296

class EPD 
    #Python fields are always public whereas Ruby's are private. attr_accessor makes them public
    attr_accessor :cs_pin, :reset_pin, :width, :busy_pin, :dc_pin, :height
    def initialize() 
        @reset_pin = epdconfig.RST_PIN
        @dc_pin = epdconfig.DC_PIN
        @busy_pin = epdconfig.BUSY_PIN
        @cs_pin = epdconfig.CS_PIN
        @width = EPD_WIDTH
        @height = EPD_HEIGHT
    end
    WF_PARTIAL_2IN9 = [
        0x0,0x40,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,
        0x80,0x80,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,
        0x40,0x40,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,
        0x0,0x80,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,
        0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,
        0x0A,0x0,0x0,0x0,0x0,0x0,0x2,  
        0x1,0x0,0x0,0x0,0x0,0x0,0x0,
        0x1,0x0,0x0,0x0,0x0,0x0,0x0,
        0x0,0x0,0x0,0x0,0x0,0x0,0x0,
        0x0,0x0,0x0,0x0,0x0,0x0,0x0,
        0x0,0x0,0x0,0x0,0x0,0x0,0x0,
        0x0,0x0,0x0,0x0,0x0,0x0,0x0,
        0x0,0x0,0x0,0x0,0x0,0x0,0x0,
        0x0,0x0,0x0,0x0,0x0,0x0,0x0,
        0x0,0x0,0x0,0x0,0x0,0x0,0x0,
        0x0,0x0,0x0,0x0,0x0,0x0,0x0,
        0x0,0x0,0x0,0x0,0x0,0x0,0x0,
        0x22,0x22,0x22,0x22,0x22,0x22,0x0,0x0,0x0,
        0x22,0x17,0x41,0xB0,0x32,0x36,
    ]    
    
    # Hardware reset
    def reset() 
        epdconfig.digital_write(@reset_pin, 1)
        epdconfig.delay_ms(200) 
        epdconfig.digital_write(@reset_pin, 0)
        epdconfig.delay_ms(5)
        epdconfig.digital_write(@reset_pin, 1)
        epdconfig.delay_ms(200)   
    end
    
    def send_command(command) 
        epdconfig.digital_write(@dc_pin, 0)
        epdconfig.digital_write(@cs_pin, 0)
        epdconfig.spi_writebyte([command])
        epdconfig.digital_write(@cs_pin, 1)
    end
    
    def send_data(data) 
        epdconfig.digital_write(@dc_pin, 1)
        epdconfig.digital_write(@cs_pin, 0)
        epdconfig.spi_writebyte([data])
        epdconfig.digital_write(@cs_pin, 1)
    end
    
    def ReadBusy() 
        logging.debug("e-Paper busy")
        while(epdconfig.digital_read(@busy_pin) == 1)       #  0: idle, 1: busy
            epdconfig.delay_ms(200) 
        end
        logging.debug("e-Paper busy release")  
    end
    
    def TurnOnDisplay() 
        send_command(0x22) # DISPLAY_UPDATE_CONTROL_2
        send_data(0xF7)
        send_command(0x20) # MASTER_ACTIVATION
        ReadBusy()
    end
    
    def TurnOnDisplay_Partial() 
        send_command(0x22) # DISPLAY_UPDATE_CONTROL_2
        send_data(0x0F)
        send_command(0x20) # MASTER_ACTIVATION
        ReadBusy()
    end
    
    def SendLut() 
        send_command(0x32)
        for i in (0..152) 
            send_data(WF_PARTIAL_2IN9[i])
        end
        ReadBusy()
    end
    
    def SetWindow(x_start, y_start, x_end, y_end) 
        send_command(0x44) # SET_RAM_X_ADDRESS_START_END_POSITION
        # x point must be the multiple of 8 or the last 3 bits will be ignored
        send_data((x_start>>3) & 0xFF)
        send_data((x_end>>3) & 0xFF)
        send_command(0x45) # SET_RAM_Y_ADDRESS_START_END_POSITION
        send_data(y_start & 0xFF)
        send_data((y_start >> 8) & 0xFF)
        send_data(y_end & 0xFF)
        send_data((y_end >> 8) & 0xFF)
    end
    
    def SetCursor(x, y) 
        send_command(0x4E) # SET_RAM_X_ADDRESS_COUNTER
        # x point must be the multiple of 8 or the last 3 bits will be ignored
        send_data(x & 0xFF)
        
        send_command(0x4F) # SET_RAM_Y_ADDRESS_COUNTER
        send_data(y & 0xFF)
        send_data((y >> 8) & 0xFF)
        ReadBusy()
    end
    
    def init() 
        if (epdconfig.module_init() != 0) 
            return -1
        end
        # EPD hardware init start     
        reSet.new
        
        ReadBusy();   
        send_command(0x12);  #SWRESET
        ReadBusy();   
        
        send_command(0x01); #Driver output control      
        send_data(0x27);
        send_data(0x01);
        send_data(0x00);
        
        send_command(0x11); #data entry mode       
        send_data(0x03);
        
        SetWindow(0, 0, @width-1, @height-1);
        
        send_command(0x21); #  Display update control
        send_data(0x00);
        send_data(0x80);	
        
        SetCursor(0, 0);
        ReadBusy();
        # EPD hardware init end
        return 0
    end
    
    def getbuffer(image) 
        # logging.debug("bufsiz = ",int(self.width/8) * self.height)
        buf = [0xFF] * (@width/8.to_i * @height)
        image_monocolor = image.convert('1')
        imwidth, imheight = image_monocolor.size
        pixels = image_monocolor.load()
        # logging.debug("imwidth = %d, imheight = %d",imwidth,imheight)
        if(imwidth == @width && imheight == @height) 
            logging.debug("Vertical")
            for y in (0..imheight-1) 
                for x in (0..imwidth-1) 
                    # Set the bits for the column of pixels at the current position.
                    if pixels[x, y] == 0 
                        buf[((x + y * @width) / 8).to_i] &= ~(0x80 >> (x % 8))
                    end
                end
            end
        elsif(imwidth == @height && imheight == @width) 
            logging.debug("Horizontal")
            for y in (0..imheight-1) 
                for x in (0..imwidth-1) 
                    newx = y
                    newy = @height - x - 1
                    if pixels[x, y] == 0 
                        buf[((newx + newy*@width) / 8).to_i] &= ~(0x80 >> (y % 8))
                    end
                end
            end
        end
        return buf
    end
    
    def display(image) 
        if (image == nil) 
            return            
        end
        send_command(0x24) # WRITE_RAM
        for j in (0..@height-1) 
            for i in (0..@width / 8.to_i-1) 
                send_data(image[i + j * @width / 8.to_i])   
            end
        end
        TurnOnDisplay()
    end
    
    def display_Base(image) 
        if (image == nil) 
            return   
        end
        
        send_command(0x24) # WRITE_RAM
        for j in (0..@height-1) 
            for i in (0..@width / 8.to_i-1) 
                send_data(image[i + j * @width / 8.to_i])
            end
        end
        
        send_command(0x26) # WRITE_RAM
        for j in (0..@height-1) 
            for i in (0..@width / 8.to_i-1) 
                send_data(image[i + j * @width / 8.to_i])   
            end
        end
        
        TurnOnDisplay()
    end
    
    def display_Partial(image) 
        if (image == nil) 
            return          
        end
        
        epdconfig.digital_write(@reset_pin, 0)
        epdconfig.delay_ms(5)
        epdconfig.digital_write(@reset_pin, 1)
        epdconfig.delay_ms(10)   
        
        SendLut();
        send_command(0x37); 
        send_data(0x00);  
        send_data(0x00);  
        send_data(0x00);  
        send_data(0x00); 
        send_data(0x00);  	
        send_data(0x40);  
        send_data(0x00);  
        send_data(0x00);   
        send_data(0x00);  
        send_data(0x00);
        
        send_command(0x3C); #BorderWavefrom
        send_data(0x80);	
        
        send_command(0x22); 
        send_data(0xC0);   
        send_command(0x20); 
        ReadBusy();
        
        SetWindow(0, 0, @width - 1, @height - 1)
        SetCursor(0, 0)
        
        send_command(0x24) # WRITE_RAM
        for j in (0..@height-1) 
            for i in (0..@width / 8.to_i-1) 
                send_data(image[i + j * @width / 8.to_i])   
            end
        end
        TurnOnDisplay_Partial()
    end
    
    def Clear(color) 
        send_command(0x24) # WRITE_RAM
        for j in (0..@height-1) 
            for i in (0..@width / 8.to_i-1) 
                send_data(color)   
            end
        end
        TurnOnDisplay()
    end
    
    def sleep() 
        send_command(0x10) # DEEP_SLEEP_MODE
        send_data(0x01)
    end
    
    def Dev_exit() 
        epdconfig.module_exit()
    end
end
### END OF FILE ###

require 'set'