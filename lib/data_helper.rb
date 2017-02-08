class DataHelper
  def self.each_keys_to_sym(hash, &each_do)
    if each_do.present?
      Hash[hash.map {|k,v| [k.to_sym, each_do.call(v, k)]}]
    else
      Hash[hash.map {|k,v| [k.to_sym, v]}]
    end
  end
  
  def self.each_keys_freeze(hash, &each_do)
    if each_do.present?
      Hash[hash.map {|k,v| [k.freeze, each_do.call(v, k)]}]
    else
      Hash[hash.map {|k,v| [k.freeze, v]}]
    end
  end

  def self.each_to_sym(arr)
    arr.map {|e| e.to_sym }
  end
end
