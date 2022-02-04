/*
* Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
*
* Licensed under the Apache License, Version 2.0 (the "License").
* You may not use this file except in compliance with the License.
* A copy of the License is located at
*
*  http://aws.amazon.com/apache2.0
*
* or in the "license" file accompanying this file. This file is distributed
* on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
* express or implied. See the License for the specific language governing
* permissions and limitations under the License.
*/

// NOTE: This file is generated and may not follow lint rules defined in your app
// Generated files can be excluded from analysis in analysis_options.yaml
// For more info, see: https://dart.dev/guides/language/analysis-options#excluding-code-from-analysis

// ignore_for_file: public_member_api_docs, file_names, unnecessary_new, prefer_if_null_operators, prefer_const_constructors, slash_for_doc_comments, annotate_overrides, non_constant_identifier_names, unnecessary_string_interpolations, prefer_adjacent_string_concatenation, unnecessary_const, dead_code

import 'package:amplify_datastore_plugin_interface/amplify_datastore_plugin_interface.dart';
import 'package:flutter/foundation.dart';


/** This is an auto generated class representing the UserData type in your schema. */
@immutable
class UserData extends Model {
  static const classType = const _UserDataModelType();
  final String id;
  final String? _email;
  final int? _freePeriods;

  @override
  getInstanceType() => classType;
  
  @override
  String getId() {
    return id;
  }
  
  String? get email {
    return _email;
  }
  
  int? get freePeriods {
    return _freePeriods;
  }
  
  const UserData._internal({required this.id, email, freePeriods}): _email = email, _freePeriods = freePeriods;
  
  factory UserData({String? id, String? email, int? freePeriods}) {
    return UserData._internal(
      id: id == null ? UUID.getUUID() : id,
      email: email,
      freePeriods: freePeriods);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UserData &&
      id == other.id &&
      _email == other._email &&
      _freePeriods == other._freePeriods;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("UserData {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("email=" + "$_email" + ", ");
    buffer.write("freePeriods=" + (_freePeriods != null ? _freePeriods!.toString() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  UserData copyWith({String? id, String? email, int? freePeriods}) {
    return UserData(
      id: id ?? this.id,
      email: email ?? this.email,
      freePeriods: freePeriods ?? this.freePeriods);
  }
  
  UserData.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _email = json['email'],
      _freePeriods = (json['freePeriods'] as num?)?.toInt();
  
  Map<String, dynamic> toJson() => {
    'id': id, 'email': _email, 'freePeriods': _freePeriods
  };

  static final QueryField ID = QueryField(fieldName: "userData.id");
  static final QueryField EMAIL = QueryField(fieldName: "email");
  static final QueryField FREEPERIODS = QueryField(fieldName: "freePeriods");
  static var schema = Model.defineSchema(define: (ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "UserData";
    modelSchemaDefinition.pluralName = "UserData";
    
    modelSchemaDefinition.authRules = [
      AuthRule(
        authStrategy: AuthStrategy.OWNER,
        ownerField: "owner",
        identityClaim: "cognito:username",
        operations: [
          ModelOperation.CREATE,
          ModelOperation.UPDATE,
          ModelOperation.DELETE,
          ModelOperation.READ
        ])
    ];
    
    modelSchemaDefinition.addField(ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(ModelFieldDefinition.field(
      key: UserData.EMAIL,
      isRequired: false,
      ofType: ModelFieldType(ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(ModelFieldDefinition.field(
      key: UserData.FREEPERIODS,
      isRequired: false,
      ofType: ModelFieldType(ModelFieldTypeEnum.int)
    ));
  });
}

class _UserDataModelType extends ModelType<UserData> {
  const _UserDataModelType();
  
  @override
  UserData fromJson(Map<String, dynamic> jsonData) {
    return UserData.fromJson(jsonData);
  }
}