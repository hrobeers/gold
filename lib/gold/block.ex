defmodule Gold.Block do

  # Returned by getblock (ppcoin v0.5.4)
  #
  # %{"bits" => "1c328077", "difficulty" => 5.06904731, "entropybit" => 1,
  #   "flags" => "proof-of-stake",
  #   "hash" => "60f27e0818638fe71493cd493344ada5544e2a3c3524336013be5b6a6ce39a17",
  #   "height" => 239584,
  #   "merkleroot" => "9759f7429e2296d34c1f182d4eb4397a295230057dfe8fb215f0aab495f3c6fa",
  #   "mint" => 0.07, "modifier" => "8d83b8a03498f838",
  #   "modifierchecksum" => "ed20661f", "nonce" => 0,
  #   "previousblockhash" => "604442c289e83e7d24945d425406f9ecfc4d9981b7235d23e6181efce5c7ba8a",
  #   "proofhash" => "000000d6ececf26abb25a0c6bc5bbd4e590d27648d863a36da832bba4159eadc",
  #   "size" => 455, "time" => "2016-11-03 08:58:20 UTC",
  #   "tx" => ["4ab229b3d4195bb6389a6b5cf96f52642c42cf6183d63142dec8aa9f60b33f96",
  #    "cb081c4d6eeeb0660c9134835aff835d4617acb77df3c667daccc4905869f81e"],
  #   "version" => 1}

  # Only interested in:
  defstruct [:flags,
             :hash,
             :height,
             :previousblockhash,
             :time,
             :txns]

  @doc """
  Creates Block struct from JSON block object.
  """
  def from_json(tx) do
    %Gold.Block{
      flags:              Map.get(tx, "flags", nil),
      hash:               Map.get(tx, "hash", nil),
      height:             Map.get(tx, "height", nil),
      previousblockhash:  Map.get(tx, "previousblockhash", nil),
      time:               Map.get(tx, "time", nil),
      txns:               Map.get(tx, "tx", nil)
    }
  end

  @doc """
  Returns `true` if argument is a bitcoin block; otherwise `false`.
  """
  def block?(%Gold.Block{}), do: true
  def block?(_), do: false

end
