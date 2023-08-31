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

// ignore_for_file: public_member_api_docs, annotate_overrides, dead_code, dead_codepublic_member_api_docs, depend_on_referenced_packages, file_names, library_private_types_in_public_api, no_leading_underscores_for_library_prefixes, no_leading_underscores_for_local_identifiers, non_constant_identifier_names, null_check_on_nullable_type_parameter, prefer_adjacent_string_concatenation, prefer_const_constructors, prefer_if_null_operators, prefer_interpolation_to_compose_strings, slash_for_doc_comments, sort_child_properties_last, unnecessary_const, unnecessary_constructor_name, unnecessary_late, unnecessary_new, unnecessary_null_aware_assignments, unnecessary_nullable_for_final_variable_declarations, unnecessary_string_interpolations, use_build_context_synchronously

import 'ModelProvider.dart';
import 'package:amplify_core/amplify_core.dart' as amplify_core;


/** This is an auto generated class representing the Settings type in your schema. */
class Settings extends amplify_core.Model {
  static const classType = const _SettingsModelType();
  final String id;
  final String? _themeMode;
  final String? _languageCode;
  final int? _jumpSeconds;
  final String? _primaryCard;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @override
  String getId() {
    return id;
  }
  
  String get themeMode {
    try {
      return _themeMode!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String get languageCode {
    try {
      return _languageCode!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  int get jumpSeconds {
    try {
      return _jumpSeconds!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String? get primaryCard {
    return _primaryCard;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const Settings._internal({required this.id, required themeMode, required languageCode, required jumpSeconds, primaryCard, createdAt, updatedAt}): _themeMode = themeMode, _languageCode = languageCode, _jumpSeconds = jumpSeconds, _primaryCard = primaryCard, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory Settings({String? id, required String themeMode, required String languageCode, required int jumpSeconds, String? primaryCard}) {
    return Settings._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      themeMode: themeMode,
      languageCode: languageCode,
      jumpSeconds: jumpSeconds,
      primaryCard: primaryCard);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Settings &&
      id == other.id &&
      _themeMode == other._themeMode &&
      _languageCode == other._languageCode &&
      _jumpSeconds == other._jumpSeconds &&
      _primaryCard == other._primaryCard;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("Settings {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("themeMode=" + "$_themeMode" + ", ");
    buffer.write("languageCode=" + "$_languageCode" + ", ");
    buffer.write("jumpSeconds=" + (_jumpSeconds != null ? _jumpSeconds!.toString() : "null") + ", ");
    buffer.write("primaryCard=" + "$_primaryCard" + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  Settings copyWith({String? id, String? themeMode, String? languageCode, int? jumpSeconds, String? primaryCard}) {
    return Settings._internal(
      id: id ?? this.id,
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
      jumpSeconds: jumpSeconds ?? this.jumpSeconds,
      primaryCard: primaryCard ?? this.primaryCard);
  }
  
  Settings copyWithModelFieldValues({
    ModelFieldValue<String>? id,
    ModelFieldValue<String>? themeMode,
    ModelFieldValue<String>? languageCode,
    ModelFieldValue<int>? jumpSeconds,
    ModelFieldValue<String?>? primaryCard
  }) {
    return Settings._internal(
      id: id == null ? this.id : id.value,
      themeMode: themeMode == null ? this.themeMode : themeMode.value,
      languageCode: languageCode == null ? this.languageCode : languageCode.value,
      jumpSeconds: jumpSeconds == null ? this.jumpSeconds : jumpSeconds.value,
      primaryCard: primaryCard == null ? this.primaryCard : primaryCard.value
    );
  }
  
  Settings.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _themeMode = json['themeMode'],
      _languageCode = json['languageCode'],
      _jumpSeconds = (json['jumpSeconds'] as num?)?.toInt(),
      _primaryCard = json['primaryCard'],
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'themeMode': _themeMode, 'languageCode': _languageCode, 'jumpSeconds': _jumpSeconds, 'primaryCard': _primaryCard, 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'themeMode': _themeMode,
    'languageCode': _languageCode,
    'jumpSeconds': _jumpSeconds,
    'primaryCard': _primaryCard,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final ID = amplify_core.QueryField(fieldName: "id");
  static final THEMEMODE = amplify_core.QueryField(fieldName: "themeMode");
  static final LANGUAGECODE = amplify_core.QueryField(fieldName: "languageCode");
  static final JUMPSECONDS = amplify_core.QueryField(fieldName: "jumpSeconds");
  static final PRIMARYCARD = amplify_core.QueryField(fieldName: "primaryCard");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "Settings";
    modelSchemaDefinition.pluralName = "Settings";
    
    modelSchemaDefinition.authRules = [
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.OWNER,
        ownerField: "owner",
        identityClaim: "cognito:username",
        provider: amplify_core.AuthRuleProvider.USERPOOLS,
        operations: const [
          amplify_core.ModelOperation.CREATE,
          amplify_core.ModelOperation.UPDATE,
          amplify_core.ModelOperation.DELETE,
          amplify_core.ModelOperation.READ
        ])
    ];
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Settings.THEMEMODE,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Settings.LANGUAGECODE,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Settings.JUMPSECONDS,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Settings.PRIMARYCARD,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.nonQueryField(
      fieldName: 'createdAt',
      isRequired: false,
      isReadOnly: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.nonQueryField(
      fieldName: 'updatedAt',
      isRequired: false,
      isReadOnly: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
  });
}

class _SettingsModelType extends amplify_core.ModelType<Settings> {
  const _SettingsModelType();
  
  @override
  Settings fromJson(Map<String, dynamic> jsonData) {
    return Settings.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'Settings';
  }
}