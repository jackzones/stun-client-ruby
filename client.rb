# -*- coding: utf-8 -*-
require 'socket'
require 'timeout'
require 'securerandom'
if RUBY_VERSION < '1.9.2'
  require 'message'
else
  require_relative 'message'
end

class Client
  STATE_INIT = 0
  STATE_IP_SAME = 1
  STATE_IP_DIFF = 2
  STATE_TEST2 = 3
  STATE_TEST3 = 4

  def initialize(host, port)
    @host = host
    @port = port
    @state = STATE_INIT
    @socket = UDPSocket.new
#    @socket.connect(@host, @port)
  end

  def run
    while true
      case @state
      when STATE_INIT then
        msg = self.test(1, @host, @port)
        if msg.nil?
          puts 'UDP Blocked'
          return nil
        elsif msg.type == Message::MESSAGE_BINDING_ERR_RESP
          puts 'error'
          return nil
        elsif msg.type == Message::MESSAGE_BINDING_RESP
          my_addr = @socket.addr
          my_addr_host = my_addr[3]
          my_addr_port = my_addr[1]
          puts 'my addr = %s:%d'%[my_addr_host, my_addr_port]
          mapped_addr = msg.attrs.find{|attr|attr.kind_of?(MappedAddress)}
          mapped_addr_host = mapped_addr.address
          mapped_addr_port = mapped_addr.port
          puts 'mapped addr = %s:%d'%[mapped_addr.address, mapped_addr.port]
          changed_addr = msg.attrs.find{|attr|attr.kind_of?(ChangedAddress)}
          changed_addr_host = changed_addr.address
          changed_addr_port = changed_addr.port
          puts 'changed addr = %s:%d'%[changed_addr.address, changed_addr.port]
          @alter_host = changed_addr_host
          @alter_port = changed_addr_port
          @mapped_addr_host = mapped_addr_host
          @mapped_addr_port = mapped_addr_port
          if my_addr_host == mapped_addr_host && my_addr_port == mapped_addr_port
            @state = STATE_IP_SAME
          else
            @state = STATE_IP_DIFF
          end
        end
      when STATE_IP_SAME then
        msg = self.test(2, @host, @port)
        if msg.nil?
          puts 'Sym. UDP Firewall'
          return nil
        elsif msg.type == Message::MESSAGE_BINDING_ERR_RESP
          puts 'error'
          return nil
        elsif msg.type == Message::MESSAGE_BINDING_RESP
          puts 'Open Internet'
          return nil
        end
      when STATE_IP_DIFF then
        msg = self.test(2, @host, @port)
        if msg.nil?
          @state = STATE_TEST2
        elsif msg.type == Message::MESSAGE_BINDING_ERR_RESP
          puts 'error'
          return nil
        elsif msg.type == Message::MESSAGE_BINDING_RESP
          puts 'Full Cone'
          return nil
        end
      when STATE_TEST2
#        @alter_socket = UDPSocket.new
#        @alter_socket.connect(@alter_host, @alter_port)
        msg = self.test(1, @alter_host, @alter_port)
        my_addr = @socket.addr
        my_addr_host = my_addr[3]
        my_addr_port = my_addr[1]
        puts 'my addr = %s:%d'%[my_addr_host, my_addr_port]
        mapped_addr = msg.attrs.find{|attr|attr.kind_of?(MappedAddress)}
        mapped_addr_host = mapped_addr.address
        mapped_addr_port = mapped_addr.port
        puts 'mapped addr = %s:%d'%[mapped_addr.address, mapped_addr.port]
        if @mapped_addr_host != mapped_addr_host || @mapped_addr_port != mapped_addr_port
          puts 'Symmetric NAT'
          return nil
        elsif msg.type == Message::MESSAGE_BINDING_ERR_RESP
          puts 'error'
          return nil
        elsif msg.type == Message::MESSAGE_BINDING_RESP
          @state = STATE_TEST3
        end
      when STATE_TEST3
        msg = self.test(3, @host, @port)
        if msg.nil?
          puts 'Port Restricted'
          return nil
        elsif msg.type == Message::MESSAGE_BINDING_ERR_RESP
          puts 'error'
          return nil
        elsif msg.type == Message::MESSAGE_BINDING_RESP
          puts 'Restricted'
          return nil
        end
      end
    end
  end

  def test(num, host, port)
    time = 0.1
    while (time <= 1.6)
      begin
        timeout(time) {
          # トランザクションID
          id = SecureRandom.random_bytes(16)
          msg = Message.new(id)
          msg.type = Message::MESSAGE_BINDING_REQ
          if num == 2
            attr = ChangeRequest.new
            attr.change_ip = true
            attr.change_port = true
            msg.attrs << attr
          elsif num == 3
            attr = ChangeRequest.new
            attr.change_port = true
            msg.attrs << attr
          end
          data = msg.pack
          @socket.send(data, 0, host, port)
          data, addr = @socket.recvfrom(1000)
          res_msg = Message.new(id)
          res_msg.unpack(data)
          my_addr = @socket.addr
          puts 'my addr = %s:%d'%[my_addr[3], my_addr[1]]
          mapped_addr = res_msg.attrs.find{|attr|attr.kind_of?(MappedAddress)}
          puts 'mapped addr = %s:%d'%[mapped_addr.address, mapped_addr.port]
          changed_addr = res_msg.attrs.find{|attr|attr.kind_of?(ChangedAddress)}
          puts 'changed addr = %s:%d'%[changed_addr.address, changed_addr.port]
          return res_msg
        }
      rescue Timeout::Error
        puts 'timeout! restarting'
      end
      sleep time
      time *= 2
    end
    return nil
  end
end
