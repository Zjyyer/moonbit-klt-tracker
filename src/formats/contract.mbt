///|
/// Schema contract information exported alongside trajectory documents.
pub(all) struct SchemaContract {
  name : String
  version : String
  required_fields : Array[String]
  optional_fields : Array[String]
  description : String
} derive(Debug)

///|
pub fn trajectory_contract() -> SchemaContract {
  {
    name: "trajectory-document",
    version: "1.0",
    required_fields: ["schema_version", "tracks", "reports"],
    optional_fields: ["state", "residual", "forward_backward_error"],
    description: "Deterministic sparse tracking observations",
  }
}

///|
pub fn contract_is_compatible(
  contract : SchemaContract,
  version : String,
) -> Bool {
  contract.version == version && contract.required_fields.length() > 0
}

///|
pub fn contract_text(contract : SchemaContract) -> String {
  let output = StringBuilder()
  output.write_string(contract.name)
  output.write_string("@")
  output.write_string(contract.version)
  output.write_string(": ")
  output.write_string(contract.description)
  output.write_string("; required=")
  for index, field in contract.required_fields {
    if index > 0 {
      output.write_string(",")
    }
    output.write_string(field)
  }
  output.write_string("; optional=")
  for index, field in contract.optional_fields {
    if index > 0 {
      output.write_string(",")
    }
    output.write_string(field)
  }
  output.to_string()
}

///|
pub fn required_field_index(contract : SchemaContract, field : String) -> Int? {
  for index, current in contract.required_fields {
    if current == field {
      return Some(index)
    }
  }
  None
}

///|
pub fn optional_field_index(contract : SchemaContract, field : String) -> Int? {
  for index, current in contract.optional_fields {
    if current == field {
      return Some(index)
    }
  }
  None
}

///|
pub fn contract_field_count(contract : SchemaContract) -> Int {
  contract.required_fields.length() + contract.optional_fields.length()
}

///|
pub fn contract_requires(
  contract : SchemaContract,
  fields : Array[String],
) -> Bool {
  for field in fields {
    if required_field_index(contract, field) is None {
      return false
    }
  }
  true
}

///|
pub fn contract_optional_only(
  contract : SchemaContract,
  fields : Array[String],
) -> Bool {
  for field in fields {
    if required_field_index(contract, field) is Some(_) ||
      optional_field_index(contract, field) is None {
      return false
    }
  }
  true
}

///|
pub fn contract_version(contract : SchemaContract) -> String {
  contract.version
}

///|
pub fn contract_name(contract : SchemaContract) -> String {
  contract.name
}

///|
pub fn contract_has_field(contract : SchemaContract, field : String) -> Bool {
  required_field_index(contract, field) is Some(_) ||
  optional_field_index(contract, field) is Some(_)
}
