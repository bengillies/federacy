RSpec::Matchers.define :contain_parsed_output do |expected|
  match do |actual|
    actual_output = pluck_keys expected.keys, actual
    expect(actual_output).to eq(expected)
  end

  def pluck_keys key_names, obj
    res = {}
    Class.new(Parslet::Transform) do
      key_names.each do |key_name|
        rule(key_name => subtree(:x)) do |dictionary|
          if res[key_name].respond_to? :push
            res[key_name] << dictionary[:x]
          elsif res[key_name].present?
            res[key_name] = [res[key_name], dictionary[:x]]
          else
            res[key_name] = dictionary[:x]
          end
        end
      end
    end.new.apply(obj)
    res
  end
end
