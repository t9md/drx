
module Drx

  # An object orieneted wrapper around the DrX::Core functions.
  #
  # This object lets you query various properties of an object.
  #
  #   info = ObjInfo.new("foo")
  #   info.has_iv_tbl?
  #   info.klass
  #
  class ObjInfo
    def initialize(obj)
      @obj = obj
      @type = Drx.get_type(@obj)
    end

    def address
      Drx.get_address(@obj)
    end

    def the_object
      @obj
    end

    # Returns true if this object is either a class or a module.
    # When true, you know it has 'm_tbl' and 'super'.
    def class_like?
      [T_CLASS, T_ICLASS, T_MODULE].include? @type
    end

    # Returns the method-table of an object.
    def m_tbl
      Drx.get_m_tbl(@obj)
    end

    # Returns the source-code position where a method is defined.
    def locate_method(method_name)
      Drx.locate_method(@obj, method_name)
    end

    def has_iv_tbl?
      t_object? || class_like?
    end

    # Returns the variable-table of an object.
    def iv_tbl
      return nil if not has_iv_tbl?
      Drx.get_iv_tbl(@obj)
    end

    # @todo: this could be nicer. perhaps define an [] accessor.
    def __get_ivar(name)
      Drx.get_ivar(@obj, name)
    end

    def singleton?
      class_like? && (Drx.get_flags(@obj) & Drx::FL_SINGLETON).nonzero?
    end

    def t_iclass?
      @type == T_ICLASS
    end

    def t_class?
      @type == T_CLASS
    end

    def t_object?
      @type == T_OBJECT
    end

    def t_module?
      @type == T_MODULE
    end

    # Note: the klass of an iclass is the included module.
    def klass
      ObjInfo.new Drx.get_klass(@obj)
    end

    # Returns the 'super' of a class-like object. Returns nil for end of chain.
    #
    # Examples: Kernel has a NULL super. Modules too have NULL super, unless
    # when 'include'ing.
    def super
      spr = Drx.get_super(@obj)
      # Note: we can't do 'if spr.nil?' because T_ICLASS doesn't "have" #nil.
      spr ? ObjInfo.new(spr) : nil
    end

    # Returns a string representation of the object. Similar to Object#inspect.
    def repr
      if t_iclass?
        'include ' + klass.repr
      elsif singleton?
        attached = __get_ivar('__attached__') || self
        attached.inspect + " 'S"
      else
        @obj.inspect
      end
    end

    # A utility function to print the inheritance hierarchy of an object.
    def examine(level = 0, title = '', &block) # :yield:
      # Note: since '@obj' may be a T_ICLASS, it doesn't repond to may methods,
      # including is_a?. So when we're querying things we're using Drx calls
      # instead.

      @@seen = {} if level.zero?
      line = ('  ' * level) + title + ' ' + repr

      seen = @@seen[address]
      @@seen[address] = true

      if seen
        line += " [seen]"
      end

      if block_given?
        yield line, self
      else
        puts line
      end

      return if seen

      if class_like?
        if spr = self.super
          spr.examine(level + 1, '[super]', &block)
        end
      end
 
      # Displaying a T_ICLASS's klass isn't very useful, because the data
      # is already mirrored in the m_tbl and iv_tvl of the T_ICLASS itself.
      if not t_iclass?
        klass.examine(level + 1, '[klass]', &block)
      end
    end
  end

end