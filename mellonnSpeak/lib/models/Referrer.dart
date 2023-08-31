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
import 'package:collection/collection.dart';


/** This is an auto generated class representing the Referrer type in your schema. */
class Referrer extends amplify_core.Model {
  static const classType = const _ReferrerModelType();
  final String id;
  final String? _name;
  final int? _members;
  final int? _purchases;
  final double? _seconds;
  final List<Promotion>? _promotions;
  final double? _discount;
  final bool? _isGroup;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @override
  String getId() {
    return id;
  }
  
  String get name {
    try {
      return _name!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  int get members {
    try {
      return _members!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  int get purchases {
    try {
      return _purchases!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  double get seconds {
    try {
      return _seconds!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  List<Promotion>? get promotions {
    return _promotions;
  }
  
  double get discount {
    try {
      return _discount!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  bool get isGroup {
    try {
      return _isGroup!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const Referrer._internal({required this.id, required name, required members, required purchases, required seconds, promotions, required discount, required isGroup, createdAt, updatedAt}): _name = name, _members = members, _purchases = purchases, _seconds = seconds, _promotions = promotions, _discount = discount, _isGroup = isGroup, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory Referrer({String? id, required String name, required int members, required int purchases, required double seconds, List<Promotion>? promotions, required double discount, required bool isGroup}) {
    return Referrer._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      name: name,
      members: members,
      purchases: purchases,
      seconds: seconds,
      promotions: promotions != null ? List<Promotion>.unmodifiable(promotions) : promotions,
      discount: discount,
      isGroup: isGroup);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Referrer &&
      id == other.id &&
      _name == other._name &&
      _members == other._members &&
      _purchases == other._purchases &&
      _seconds == other._seconds &&
      DeepCollectionEquality().equals(_promotions, other._promotions) &&
      _discount == other._discount &&
      _isGroup == other._isGroup;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("Referrer {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("name=" + "$_name" + ", ");
    buffer.write("members=" + (_members != null ? _members!.toString() : "null") + ", ");
    buffer.write("purchases=" + (_purchases != null ? _purchases!.toString() : "null") + ", ");
    buffer.write("seconds=" + (_seconds != null ? _seconds!.toString() : "null") + ", ");
    buffer.write("discount=" + (_discount != null ? _discount!.toString() : "null") + ", ");
    buffer.write("isGroup=" + (_isGroup != null ? _isGroup!.toString() : "null") + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  Referrer copyWith({String? id, String? name, int? members, int? purchases, double? seconds, List<Promotion>? promotions, double? discount, bool? isGroup}) {
    return Referrer._internal(
      id: id ?? this.id,
      name: name ?? this.name,
      members: members ?? this.members,
      purchases: purchases ?? this.purchases,
      seconds: seconds ?? this.seconds,
      promotions: promotions ?? this.promotions,
      discount: discount ?? this.discount,
      isGroup: isGroup ?? this.isGroup);
  }
  
  Referrer copyWithModelFieldValues({
    ModelFieldValue<String>? id,
    ModelFieldValue<String>? name,
    ModelFieldValue<int>? members,
    ModelFieldValue<int>? purchases,
    ModelFieldValue<double>? seconds,
    ModelFieldValue<List<Promotion>>? promotions,
    ModelFieldValue<double>? discount,
    ModelFieldValue<bool>? isGroup
  }) {
    return Referrer._internal(
      id: id == null ? this.id : id.value,
      name: name == null ? this.name : name.value,
      members: members == null ? this.members : members.value,
      purchases: purchases == null ? this.purchases : purchases.value,
      seconds: seconds == null ? this.seconds : seconds.value,
      promotions: promotions == null ? this.promotions : promotions.value,
      discount: discount == null ? this.discount : discount.value,
      isGroup: isGroup == null ? this.isGroup : isGroup.value
    );
  }
  
  Referrer.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _name = json['name'],
      _members = (json['members'] as num?)?.toInt(),
      _purchases = (json['purchases'] as num?)?.toInt(),
      _seconds = (json['seconds'] as num?)?.toDouble(),
      _promotions = json['promotions'] is List
        ? (json['promotions'] as List)
          .where((e) => e?['serializedData'] != null)
          .map((e) => Promotion.fromJson(new Map<String, dynamic>.from(e['serializedData'])))
          .toList()
        : null,
      _discount = (json['discount'] as num?)?.toDouble(),
      _isGroup = json['isGroup'],
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'name': _name, 'members': _members, 'purchases': _purchases, 'seconds': _seconds, 'promotions': _promotions?.map((Promotion? e) => e?.toJson()).toList(), 'discount': _discount, 'isGroup': _isGroup, 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'name': _name,
    'members': _members,
    'purchases': _purchases,
    'seconds': _seconds,
    'promotions': _promotions,
    'discount': _discount,
    'isGroup': _isGroup,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final ID = amplify_core.QueryField(fieldName: "id");
  static final NAME = amplify_core.QueryField(fieldName: "name");
  static final MEMBERS = amplify_core.QueryField(fieldName: "members");
  static final PURCHASES = amplify_core.QueryField(fieldName: "purchases");
  static final SECONDS = amplify_core.QueryField(fieldName: "seconds");
  static final PROMOTIONS = amplify_core.QueryField(
    fieldName: "promotions",
    fieldType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.model, ofModelName: 'Promotion'));
  static final DISCOUNT = amplify_core.QueryField(fieldName: "discount");
  static final ISGROUP = amplify_core.QueryField(fieldName: "isGroup");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "Referrer";
    modelSchemaDefinition.pluralName = "Referrers";
    
    modelSchemaDefinition.authRules = [
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.PRIVATE,
        operations: const [
          amplify_core.ModelOperation.CREATE,
          amplify_core.ModelOperation.UPDATE,
          amplify_core.ModelOperation.DELETE,
          amplify_core.ModelOperation.READ
        ]),
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.PUBLIC,
        operations: const [
          amplify_core.ModelOperation.READ
        ]),
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.PRIVATE,
        provider: amplify_core.AuthRuleProvider.IAM,
        operations: const [
          amplify_core.ModelOperation.READ
        ]),
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.PUBLIC,
        provider: amplify_core.AuthRuleProvider.IAM,
        operations: const [
          amplify_core.ModelOperation.READ
        ])
    ];
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Referrer.NAME,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Referrer.MEMBERS,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Referrer.PURCHASES,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Referrer.SECONDS,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.double)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.hasMany(
      key: Referrer.PROMOTIONS,
      isRequired: true,
      ofModelName: 'Promotion',
      associatedKey: Promotion.REFERRERID
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Referrer.DISCOUNT,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.double)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Referrer.ISGROUP,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.bool)
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

class _ReferrerModelType extends amplify_core.ModelType<Referrer> {
  const _ReferrerModelType();
  
  @override
  Referrer fromJson(Map<String, dynamic> jsonData) {
    return Referrer.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'Referrer';
  }
}