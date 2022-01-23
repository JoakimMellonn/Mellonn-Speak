// To parse this JSON data, do
//
//     final transcription = transcriptionFromJson(jsonString);

import 'dart:convert';

Transcription transcriptionFromJson(String str) =>
    Transcription.fromJson(json.decode(str));

String transcriptionToJson(Transcription data) => json.encode(data.toJson());

class Transcription {
  Transcription({
    required this.jobName,
    required this.accountId,
    required this.results,
    required this.status,
  });

  String jobName;
  String accountId;
  Results results;
  String status;

  factory Transcription.fromJson(Map<String, dynamic> json) => Transcription(
        jobName: json["jobName"],
        accountId: json["accountId"],
        results: Results.fromJson(json["results"]),
        status: json["status"],
      );

  Map<String, dynamic> toJson() => {
        "jobName": jobName,
        "accountId": accountId,
        "results": results.toJson(),
        "status": status,
      };
}

class Results {
  Results({
    required this.transcripts,
    required this.speakerLabels,
    required this.items,
  });

  List<Transcript> transcripts;
  SpeakerLabels speakerLabels;
  List<Item> items;

  factory Results.fromJson(Map<String, dynamic> json) => Results(
        transcripts: List<Transcript>.from(
            json["transcripts"].map((x) => Transcript.fromJson(x))),
        speakerLabels: SpeakerLabels.fromJson(json["speaker_labels"]),
        items: List<Item>.from(json["items"].map((x) => Item.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "transcripts": List<dynamic>.from(transcripts.map((x) => x.toJson())),
        "speaker_labels": speakerLabels.toJson(),
        "items": List<dynamic>.from(items.map((x) => x.toJson())),
      };
}

class Item {
  Item({
    required this.startTime,
    required this.endTime,
    required this.alternatives,
    required this.type,
  });

  String startTime;
  String endTime;
  List<Alternative> alternatives;
  String type;

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        startTime: json["start_time"] == null ? '' : json["start_time"],
        endTime: json["end_time"] == null ? '' : json["end_time"],
        alternatives: List<Alternative>.from(
            json["alternatives"].map((x) => Alternative.fromJson(x))),
        type: json["type"],
      );

  Map<String, dynamic> toJson() => {
        "start_time": startTime == null ? '' : startTime,
        "end_time": endTime == null ? '' : endTime,
        "alternatives": List<dynamic>.from(alternatives.map((x) => x.toJson())),
        "type": type,
      };
}

class Alternative {
  Alternative({
    required this.confidence,
    required this.content,
  });

  String confidence;
  String content;

  factory Alternative.fromJson(Map<String, dynamic> json) => Alternative(
        confidence: json["confidence"],
        content: json["content"],
      );

  Map<String, dynamic> toJson() => {
        "confidence": confidence,
        "content": content,
      };
}

class SpeakerLabels {
  SpeakerLabels({
    required this.speakers,
    required this.segments,
  });

  int speakers;
  List<Segment> segments;

  factory SpeakerLabels.fromJson(Map<String, dynamic> json) => SpeakerLabels(
        speakers: json["speakers"],
        segments: List<Segment>.from(
            json["segments"].map((x) => Segment.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "speakers": speakers,
        "segments": List<dynamic>.from(segments.map((x) => x.toJson())),
      };
}

class Segment {
  Segment({
    required this.startTime,
    required this.speakerLabel,
    required this.endTime,
    required this.items,
  });

  String startTime;
  String speakerLabel;
  String endTime;
  List<SegmentItem> items;

  factory Segment.fromJson(Map<String, dynamic> json) => Segment(
        startTime: json["start_time"],
        speakerLabel: json["speaker_label"],
        endTime: json["end_time"],
        items: List<SegmentItem>.from(
            json["items"].map((x) => SegmentItem.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "start_time": startTime,
        "speaker_label": speakerLabel,
        "end_time": endTime,
        "items": List<dynamic>.from(items.map((x) => x.toJson())),
      };
}

class SegmentItem {
  SegmentItem({
    required this.startTime,
    required this.speakerLabel,
    required this.endTime,
  });

  String startTime;
  String speakerLabel;
  String endTime;

  factory SegmentItem.fromJson(Map<String, dynamic> json) => SegmentItem(
        startTime: json["start_time"],
        speakerLabel: json["speaker_label"],
        endTime: json["end_time"],
      );

  Map<String, dynamic> toJson() => {
        "start_time": startTime,
        "speaker_label": speakerLabel,
        "end_time": endTime,
      };
}

class Transcript {
  Transcript({
    required this.transcript,
  });

  String transcript;

  factory Transcript.fromJson(Map<String, dynamic> json) => Transcript(
        transcript: json["transcript"],
      );

  Map<String, dynamic> toJson() => {
        "transcript": transcript,
      };
}
