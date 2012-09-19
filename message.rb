# -*- coding: utf-8 -*-

require 'set'
if RUBY_VERSION < '1.9.2'
  require 'attribute'
else
  require_relative 'attribute'
end

class Message
  # メッセージタイプ
  MESSAGE_BINDING_REQ = 0x0001
  MESSAGE_BINDING_RESP = 0x0101
  MESSAGE_BINDING_ERR_RESP = 0x0111
  MESSAGE_SHARED_SECRET_REQ = 0x0002
  MESSAGE_SHARED_SECRET_RESP = 0x0102
  MESSAGE_SHARED_SECRET_ERR_RESP = 0x0112

  TYPES = Set.new [MESSAGE_BINDING_REQ,
                   MESSAGE_BINDING_RESP,
                   MESSAGE_BINDING_ERR_RESP,
                   MESSAGE_SHARED_SECRET_REQ,
                   MESSAGE_SHARED_SECRET_RESP,
                   MESSAGE_SHARED_SECRET_ERR_RESP]
  # メッセージID
  attr_accessor :id
  # メッセージタイプ
  attr_accessor :type
  # 属性データの集合
  attr_accessor :attrs

  def initialize(id)
    @id = id
    @attrs = []
  end

  # このメッセージをバイト列に変換する
  def pack
    attr_datas = @attrs.map{|attr|attr.pack}
    length = attr_datas.inject(0){|result, item| result + item.size }
    data = [@type, length].pack("nn") + @id
    data += attr_datas*''
    data
  end

  def unpack(data)
    @attrs = []
    header = data.unpack("nn")
    type = header[0]
    unless TYPES.include?(type)
      p 'unsupported msg type: ' + type
      return nil
    end
    @type = type
    length = header[1]
    id = data[4...20]
    @id = id
    data = data[20..-1]
    while data.size > 0
      header = data.unpack("nn")
      type = header[0]
      length = header[1]
      value = data[4...4+length]
      attr = Attribute.parse(type, value)
      @attrs << attr unless attr.nil?
      data = data[4+length..-1]
    end
  end
end
