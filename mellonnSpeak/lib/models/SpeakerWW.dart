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


/** This is an auto generated class representing the SpeakerWW type in your schema. */
@immutable
class SpeakerWW extends Model {
  static const classType = const _SpeakerWWModelType();
  final String id;
  final double? _startTime;
  final String? _speakerLabel;
  final double? _endTime;
  final String? _pronouncedWords;

  @override
  getInstanceType() => classType;
  
  @override
  String getId() {
    return id;
  }
  
  double? get startTime {
    return _startTime;
  }
  
  String? get speakerLabel {
    return _speakerLabel;
  }
  
  double? get endTime {
    return _endTime;
  }
  
  String? get pronouncedWords {
    return _pronouncedWords;
  }
  
  const SpeakerWW._internal({required this.id, startTime, speakerLabel, endTime, pronouncedWords}): _startTime = startTime, _speakerLabel = speakerLabel, _endTime = endTime, _pronouncedWords = pronouncedWords;
  
  factory SpeakerWW({String? id, double? startTime, String? speakerLabel, double? endTime, String? pronouncedWords}) {
    return SpeakerWW._internal(
      id: id == null ? UUID.getUUID() : id,
      startTime: startTime,
      speakerLabel: speakerLabel,
      endTime: endTime,
      pronouncedWords: pronouncedWords);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SpeakerWW &&
      id == other.id &&
      _startTime == other._startTime &&
      _speakerLabel == other._speakerLabel &&
      _endTime == other._endTime &&
      _pronouncedWords == other._pronouncedWords;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("SpeakerWW {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("startTime=" + (_startTime != null ? _startTime!.toString() : "null") + ", ");
    buffer.write("speakerLabel=" + "$_speakerLabel" + ", ");
    buffer.write("endTime=" + (_endTime != null ? _endTime!.toString() : "null") + ", ");
    buffer.write("pronouncedWords=" + "$_pronouncedWords");
    buffer.write("}");
    
    return buffer.toString();
  }
  
  SpeakerWW copyWith({String? id, double? startTime, String? speakerLabel, double? endTime, String? pronouncedWords}) {
    return SpeakerWW(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      speakerLabel: speakerLabel ?? this.speakerLabel,
      endTime: endTime ?? this.endTime,
      pronouncedWords: pronouncedWords ?? this.pronouncedWords);
  }
  
  SpeakerWW.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _startTime = (json['startTime'] as num?)?.toDouble(),
      _speakerLabel = json['speakerLabel'],
      _endTime = (json['endTime'] as num?)?.toDouble(),
      _pronouncedWords = json['pronouncedWords'];
  
  Map<String, dynamic> toJson() => {
    'id': id, 'startTime': _startTime, 'speakerLabel': _speakerLabel, 'endTime': _endTime, 'pronouncedWords': _pronouncedWords
  };

  static final QueryField ID = QueryField(fieldName: "speakerWW.id");
  static final QueryField STARTTIME = QueryField(fieldName: "startTime");
  static final QueryField SPEAKERLABEL = QueryField(fieldName: "speakerLabel");
  static final QueryField ENDTIME = QueryField(fieldName: "endTime");
  static final QueryField PRONOUNCEDWORDS = QueryField(fieldName: "pronouncedWords");
  static var schema = Model.defineSchema(define: (ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "SpeakerWW";
    modelSchemaDefinition.pluralName = "SpeakerWWS";
    
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
      key: SpeakerWW.STARTTIME,
      isRequired: false,
      ofType: ModelFieldType(ModelFieldTypeEnum.double)
    ));
    
    modelSchemaDefinition.addField(ModelFieldDefinition.field(
      key: SpeakerWW.SPEAKERLABEL,
      isRequired: false,
      ofType: ModelFieldType(ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(ModelFieldDefinition.field(
      key: SpeakerWW.ENDTIME,
      isRequired: false,
      ofType: ModelFieldType(ModelFieldTypeEnum.double)
    ));
    
    modelSchemaDefinition.addField(ModelFieldDefinition.field(
      key: SpeakerWW.PRONOUNCEDWORDS,
      isRequired: false,
      ofType: ModelFieldType(ModelFieldTypeEnum.string)
    ));
  });
}

class _SpeakerWWModelType extends ModelType<SpeakerWW> {
  const _SpeakerWWModelType();
  
  @override
  SpeakerWW fromJson(Map<String, dynamic> jsonData) {
    return SpeakerWW.fromJson(jsonData);
  }
}