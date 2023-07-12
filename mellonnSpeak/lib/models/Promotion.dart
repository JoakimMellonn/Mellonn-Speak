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


/** This is an auto generated class representing the Promotion type in your schema. */
class Promotion extends amplify_core.Model {
  static const classType = const _PromotionModelType();
  final String id;
  final PromotionType? _type;
  final String? _code;
  final amplify_core.TemporalDate? _date;
  final int? _freePeriods;
  final int? _uses;
  final String? _referrerID;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @override
  String getId() {
    return id;
  }
  
  PromotionType get type {
    try {
      return _type!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String get code {
    try {
      return _code!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  amplify_core.TemporalDate get date {
    try {
      return _date!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  int get freePeriods {
    try {
      return _freePeriods!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  int get uses {
    try {
      return _uses!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String? get referrerID {
    return _referrerID;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const Promotion._internal({required this.id, required type, required code, required date, required freePeriods, required uses, referrerID, createdAt, updatedAt}): _type = type, _code = code, _date = date, _freePeriods = freePeriods, _uses = uses, _referrerID = referrerID, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory Promotion({String? id, required PromotionType type, required String code, required amplify_core.TemporalDate date, required int freePeriods, required int uses, String? referrerID}) {
    return Promotion._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      type: type,
      code: code,
      date: date,
      freePeriods: freePeriods,
      uses: uses,
      referrerID: referrerID);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Promotion &&
      id == other.id &&
      _type == other._type &&
      _code == other._code &&
      _date == other._date &&
      _freePeriods == other._freePeriods &&
      _uses == other._uses &&
      _referrerID == other._referrerID;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("Promotion {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("type=" + (_type != null ? amplify_core.enumToString(_type)! : "null") + ", ");
    buffer.write("code=" + "$_code" + ", ");
    buffer.write("date=" + (_date != null ? _date!.format() : "null") + ", ");
    buffer.write("freePeriods=" + (_freePeriods != null ? _freePeriods!.toString() : "null") + ", ");
    buffer.write("uses=" + (_uses != null ? _uses!.toString() : "null") + ", ");
    buffer.write("referrerID=" + "$_referrerID" + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  Promotion copyWith({String? id, PromotionType? type, String? code, amplify_core.TemporalDate? date, int? freePeriods, int? uses, String? referrerID}) {
    return Promotion._internal(
      id: id ?? this.id,
      type: type ?? this.type,
      code: code ?? this.code,
      date: date ?? this.date,
      freePeriods: freePeriods ?? this.freePeriods,
      uses: uses ?? this.uses,
      referrerID: referrerID ?? this.referrerID);
  }
  
  Promotion copyWithModelFieldValues({
    ModelFieldValue<String>? id,
    ModelFieldValue<PromotionType>? type,
    ModelFieldValue<String>? code,
    ModelFieldValue<amplify_core.TemporalDate>? date,
    ModelFieldValue<int>? freePeriods,
    ModelFieldValue<int>? uses,
    ModelFieldValue<String?>? referrerID
  }) {
    return Promotion._internal(
      id: id == null ? this.id : id.value,
      type: type == null ? this.type : type.value,
      code: code == null ? this.code : code.value,
      date: date == null ? this.date : date.value,
      freePeriods: freePeriods == null ? this.freePeriods : freePeriods.value,
      uses: uses == null ? this.uses : uses.value,
      referrerID: referrerID == null ? this.referrerID : referrerID.value
    );
  }
  
  Promotion.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _type = amplify_core.enumFromString<PromotionType>(json['type'], PromotionType.values),
      _code = json['code'],
      _date = json['date'] != null ? amplify_core.TemporalDate.fromString(json['date']) : null,
      _freePeriods = (json['freePeriods'] as num?)?.toInt(),
      _uses = (json['uses'] as num?)?.toInt(),
      _referrerID = json['referrerID'],
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'type': amplify_core.enumToString(_type), 'code': _code, 'date': _date?.format(), 'freePeriods': _freePeriods, 'uses': _uses, 'referrerID': _referrerID, 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'type': _type,
    'code': _code,
    'date': _date,
    'freePeriods': _freePeriods,
    'uses': _uses,
    'referrerID': _referrerID,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final ID = amplify_core.QueryField(fieldName: "id");
  static final TYPE = amplify_core.QueryField(fieldName: "type");
  static final CODE = amplify_core.QueryField(fieldName: "code");
  static final DATE = amplify_core.QueryField(fieldName: "date");
  static final FREEPERIODS = amplify_core.QueryField(fieldName: "freePeriods");
  static final USES = amplify_core.QueryField(fieldName: "uses");
  static final REFERRERID = amplify_core.QueryField(fieldName: "referrerID");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "Promotion";
    modelSchemaDefinition.pluralName = "Promotions";
    
    modelSchemaDefinition.authRules = [
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.PRIVATE,
        operations: const [
          amplify_core.ModelOperation.CREATE,
          amplify_core.ModelOperation.UPDATE,
          amplify_core.ModelOperation.DELETE,
          amplify_core.ModelOperation.READ
        ])
    ];
    
    modelSchemaDefinition.indexes = [
      amplify_core.ModelIndex(fields: const ["referrerID"], name: "byReferrer")
    ];
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Promotion.TYPE,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.enumeration)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Promotion.CODE,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Promotion.DATE,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.date)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Promotion.FREEPERIODS,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Promotion.USES,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Promotion.REFERRERID,
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

class _PromotionModelType extends amplify_core.ModelType<Promotion> {
  const _PromotionModelType();
  
  @override
  Promotion fromJson(Map<String, dynamic> jsonData) {
    return Promotion.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'Promotion';
  }
}