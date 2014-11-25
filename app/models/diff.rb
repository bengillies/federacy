class Diff
  attr_reader :old, :new, :type

  # type is :tiddler or :space
  # old and new are the things to diff
  def initialize type, old, new
    @old = old || {}
    @new = new || {}
    @type = type
    @fields = if type == :tiddler
      %w(title tags content_type text fields user_id created)
    else
      %w(name description)
    end
  end

  def html
    @html ||= to_html
  end

  # returns a hash with values replaced by html diff output for that key
  def to_html
    diff(@old, @new, @fields).reduce({}) do |diffed_output, (key, val)|
      if val.class == Hash
        diffed_output[key] = val.reduce({}) do |d_o, (k, v)|
          d_o[k] = v.to_s :html
          d_o
        end
      else
        diffed_output[key] = val.to_s :html
      end
      diffed_output
    end
  end

  def as_json
    simple_diff(@old, @new, "", @fields)
  end

  # returns json compliant with JSON Patch
  def to_json arg
    as_json.to_json
  end

  private

  def exists? obj, key
    key.respond_to?(:to_sym) && obj.respond_to?(key) ? obj.send(key).present? : obj[key].present?
  end

  def value obj, key
    key.respond_to?(:to_sym) && obj.respond_to?(key) ? obj.send(key) : obj[key]
  end


  # As Diffy uses the built in diff command we need to conditionally add a
  # newline to stop the output containing a "No newline at end of file" line.
  def add_newline text
    if text =~ /\n$/m
      text
    else
      text + "\n"
    end
  end

  # Do a simple comparison of values, rather than a proper diff
  def simple_diff old_obj, new_obj, path_prefix, fields=nil
    fields ||= old_obj.keys.concat(new_obj.keys).uniq
    return nil unless fields.to_a.length > 0
    fields.map do |field|
      simple_diff_field(old_obj, new_obj, path_prefix, field)
    end.flatten.compact
  end

  def simple_diff_field old_obj, new_obj, path_prefix, field
    path = "#{path_prefix}/#{field}"
    old_val = value(old_obj, field)
    new_val = value(new_obj, field)

    return nil unless old_val || new_val

    if field == "fields"
      return simple_diff(old_val, new_val, path)
    elsif field == "tags"
      range = if old_val.length > new_val.length
        0..(old_val.length - 1)
      else
        0..(new_val.length - 1)
      end
      return simple_diff(old_val, new_val, path, range)
    end

    has_old = exists?(old_obj, field)
    has_new = exists?(new_obj, field)

    if has_old && has_new && old_val.to_s != new_val.to_s
      { op: 'replace', path: path, value: new_val.to_s }
    elsif !has_old && has_new
      { op: 'add', path: path, value: new_val.to_s }
    elsif !has_new && has_old
      { op: 'remove', path: path }
    end
  end

  # do a full diff of values
  def diff old_obj, new_obj, fields=nil
    fields ||= old_obj.keys.concat(new_obj.keys).uniq
    return nil unless fields.length > 0

    fields.reduce({}) do |diffed_output, field|
      val = diff_field(field, old_obj, new_obj)
      diffed_output[field] = val if val
      diffed_output
    end
  end

  def diff_field key, old_obj, new_obj
    old_val = value(old_obj, key)
    new_val = value(new_obj, key)

    return nil unless old_val || new_val

    if key == "fields"
      return diff(old_val, new_val)
    elsif key == "tags"
      return nil unless old_val.length > 0 || new_val.length > 0
    end
    Diffy::Diff.new(add_newline(old_val.to_s), add_newline(new_val.to_s),
      allow_empty_diff: false)
  end
end
