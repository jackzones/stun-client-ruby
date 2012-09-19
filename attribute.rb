# -*- coding: utf-8 -*-
class Attribute
  # 属性タイプ
  ATTR_MAPPED_ADDRESS = 0x0001
  ATTR_RESPONSE_ADDRESS = 0x0002
  ATTR_CHANGE_REQUEST = 0x0003
  ATTR_SOURCE_ADDRESS = 0x0004
  ATTR_CHANGED_ADDRESS = 0x0005
  ATTR_USERNAME = 0x0006
  ATTR_PASSWORD = 0x0007
  ATTR_MESSAGE_INTEGRITY = 0x0008
  ATTR_ERROR_CODE = 0x0009
  ATTR_UNKNOWN_ATTRIBUTES = 0x000a
  ATTR_REFLECTED_FROM = 0x000b

  attr_accessor :type, :data

  def parse(data)
    header = data.unpack("nn")
    @type = header[0]
    @data = data[4...4+header[1]]
  end

  # この属性をバイト列に変換する
  def pack
    data = [@type, @data.size].pack("nn")
    data << @data
    data
  end

  def Attribute.parse(type, data)
    case type
    when ATTR_MAPPED_ADDRESS then
      MappedAddress.new(data)
    when ATTR_SOURCE_ADDRESS then
      SourceAddress.new(data)
    when ATTR_CHANGED_ADDRESS then
      ChangedAddress.new(data)
    when ATTR_REFLECTED_FROM then
      ReflectedFrom.new(data)
    else
      puts 'unsupported attribute type: ' + type.to_s
    end
  end
end

class MappedAddress < Attribute
  attr_accessor :port, :address

  def initialize(data)
    @type = ATTR_MAPPED_ADDRESS
    @data = data
    values = data.unpack("CCnCCCC")
    @port = values[2]
    @address = values[3..-1]*"."
  end
end

class SourceAddress < Attribute
  attr_accessor :port, :address

  def initialize(data)
    @type = ATTR_SOURCE_ADDRESS
    @data = data
    values = data.unpack("CCnCCCC")
    @port = values[2]
    @address = values[3..-1]*"."
  end
end

class ChangedAddress < Attribute
  attr_accessor :port, :address

  def initialize(data)
    @type = ATTR_CHANGED_ADDRESS
    @data = data
    values = data.unpack("CCnCCCC")
    @port = values[2]
    @address = values[3..-1]*"."
  end
end

class ReflectedFrom < Attribute
  attr_accessor :port, :address

  def initialize(data)
    @type = ATTR_REFLECTED_FROM
    @data = data
    values = data.unpack("CCnCCCC")
    @port = values[2]
    @address = values[3..-1]*"."
  end
end

class ChangeRequest < Attribute
  attr_accessor :change_ip, :change_port

  def pack
    @type = Attribute::ATTR_CHANGE_REQUEST
    @data = [(@change_ip ? 4 : 0) + (@change_port ? 2 : 0)].pack("N")
    super
  end
end
