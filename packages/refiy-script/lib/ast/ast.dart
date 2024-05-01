import 'package:pub_semver/pub_semver.dart';
import '../declaration/namespace/declaration_namespace.dart';
import '../parser/token.dart';
import '../source/source.dart';
import '../declaration/declaration.dart';
import '../../resource/resource.dart' show HTResourceType;
import '../../source/line_info.dart';
import '../error/error.dart';
import '../../common/internal_identifier.dart';
import '../common/function_category.dart';

part 'visitor/abstract_ast_visitor.dart';

abstract class ASTNode {
  final String type;

  List<ASTAnnotation> precedings = [];

  ASTAnnotation? trailing;

  ASTAnnotation? trailingAfterComma;

  List<ASTAnnotation> succeedings = [];

  String get documentation {
    final documentation = StringBuffer();
    for (final line in precedings) {
      if (line.isDocumentation) {
        documentation.writeln(line.content);
      }
    }
    return documentation.toString();
  }

  final bool isStatement;

  bool get isExpression => !isStatement;

  final bool isBlock;

  bool get isConstValue => value != null;

  final bool isAwait;
  dynamic value;

  final RSSource? source;

  final int line;

  final int column;

  final int offset;

  final int length;

  int get end => offset + length;

  /// Visit this node
  dynamic accept(AbstractASTVisitor visitor);

  /// Visit all the sub nodes of this, doing nothing by default.
  void subAccept(AbstractASTVisitor visitor) {}

  ASTNode(
    this.type, {
    this.isStatement = false,
    this.isAwait = false,
    this.isBlock = false,
    this.source,
    this.line = 0,
    this.column = 0,
    this.offset = 0,
    this.length = 0,
  });
}

abstract class ASTAnnotation extends ASTNode {
  final String content;

  final bool isDocumentation;

  ASTAnnotation(
    super.type, {
    required this.content,
    required this.isDocumentation,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  });
}

class ASTComment extends ASTAnnotation {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitComment(this);

  final bool isMultiLine;

  final bool isTrailing;

  ASTComment({
    required String content,
    required super.isDocumentation,
    required this.isMultiLine,
    required this.isTrailing,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(InternalIdentifier.comment, content: content);

  ASTComment.fromCommentToken(TokenComment token)
      : this(
          content: token.literal,
          isDocumentation: token.isDocumentation,
          isMultiLine: token.isMultiLine,
          isTrailing: token.isTrailing,
        );
}

class ASTEmptyLine extends ASTAnnotation {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitEmptyLine(this);

  ASTEmptyLine({
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(
          InternalIdentifier.emptyLine,
          content: '\n',
          isDocumentation: false,
        );
}

/// Parse result of a single file
class ASTSource extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitSource(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    for (final stmt in nodes) {
      stmt.accept(visitor);
    }
  }

  String get fullName => source!.fullName;

  HTResourceType get resourceType => source!.type;

  LineInfo get lineInfo => source!.lineInfo;

  final List<ImportExportDecl> imports;

  final List<ASTNode> nodes;

  final List<RSError> errors;

  bool isResolved = false;

  ASTSource({
    required this.nodes,
    this.imports = const [],
    this.errors = const [],
    required super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(InternalIdentifier.source, isStatement: true) {
  }
}

class ASTCompilation extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitCompilation(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    for (final node in values.values) {
      node.accept(visitor);
    }
    for (final node in sources.values) {
      node.accept(visitor);
    }
  }

  final Map<String, ASTSource> values;

  final Map<String, ASTSource> sources;

  final String entryFullname;

  final HTResourceType entryResourceType;

  final List<RSError> errors;

  final Version? version;

  ASTCompilation({
    required this.values,
    required this.sources,
    required this.entryFullname,
    required this.entryResourceType,
    required this.errors,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
    this.version,
  }) : super(InternalIdentifier.compilation, isStatement: true) {
  }
}

class ASTEmpty extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitEmptyExpr(this);

  ASTEmpty({
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(InternalIdentifier.empty);
}

class ASTLiteralNull extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitNullExpr(this);

  ASTLiteralNull({
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(InternalIdentifier.literalNull);
}

class ASTLiteralBoolean extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitBooleanExpr(this);

  final bool _value;

  @override
  bool get value => _value;

  ASTLiteralBoolean(
    this._value, {
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(InternalIdentifier.literalBoolean);
}

class ASTLiteralInteger extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) =>
      visitor.visitIntLiteralExpr(this);

  final int _value;

  @override
  int get value => _value;

  ASTLiteralInteger(
    this._value, {
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(InternalIdentifier.literalInteger);
}

class ASTLiteralFloat extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) =>
      visitor.visitFloatLiteralExpr(this);

  final double _value;

  @override
  double get value => _value;

  ASTLiteralFloat(
    this._value, {
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(InternalIdentifier.literalFloat);
}

class ASTLiteralString extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) =>
      visitor.visitStringLiteralExpr(this);

  final String _value;

  @override
  String get value => _value;

  final String quotationLeft;

  final String quotationRight;

  ASTLiteralString(
    this._value,
    this.quotationLeft,
    this.quotationRight, {
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(InternalIdentifier.literalString);
}

class ASTStringInterpolation extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) =>
      visitor.visitStringInterpolationExpr(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    for (final expr in interpolations) {
      expr.accept(visitor);
    }
  }

  final String text;

  final String quotationLeft;

  final String quotationRight;

  final List<ASTNode> interpolations;

  ASTStringInterpolation(
    this.text,
    this.quotationLeft,
    this.quotationRight,
    this.interpolations, {
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(
          InternalIdentifier.stringInterpolation,
          isAwait: interpolations.any((element) => element.isAwait),
        ) {
    // for (final ast in interpolations) {
    //   ast.parent = this;
    // }
  }
}

class IdentifierExpr extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) =>
      visitor.visitIdentifierExpr(this);

  final String id;

  final bool isMarked;

  final bool isLocal;

  /// This value is null untill assigned by analyzer
  RSDeclarationNamespace<ASTNode?>? analysisNamespace;

  /// This value is null untill assigned by analyzer
  HTDeclaration? declaration;

  IdentifierExpr(
    this.id, {
    this.isMarked = false,
    this.isLocal = true,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(InternalIdentifier.identifierExpression);

  IdentifierExpr.fromToken(
    Token idTok, {
    bool isMarked = false,
    bool isLocal = true,
    RSSource? source,
  }) : this(idTok.literal,
            isLocal: isLocal,
            source: source,
            line: idTok.line,
            column: idTok.column,
            offset: idTok.offset,
            length: idTok.length);
}

class SpreadExpr extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitSpreadExpr(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    collection.accept(visitor);
  }

  final ASTNode collection;

  SpreadExpr(
    this.collection, {
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(
          InternalIdentifier.spreadExpression,
          isAwait: collection.isAwait,
        );
}

class CommaExpr extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitCommaExpr(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    for (final item in list) {
      item.accept(visitor);
    }
  }

  final List<ASTNode> list;

  final bool isLocal;

  CommaExpr(
    this.list, {
    this.isLocal = true,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(
          InternalIdentifier.commaExpression,
          isAwait: list.any((element) => element.isAwait),
        );
}

class ListExpr extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitListExpr(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    for (final item in list) {
      item.accept(visitor);
    }
  }

  final List<ASTNode> list;

  ListExpr(
    this.list, {
    RSSource? source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(
          InternalIdentifier.literalList,
          isAwait: list.any((element) => element.isAwait),
        );
}

class InOfExpr extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitInOfExpr(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    collection.accept(visitor);
  }

  final ASTNode collection;

  final bool valueOf;

  InOfExpr(
    this.collection,
    this.valueOf, {
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(
          InternalIdentifier.inOfExpression,
          isAwait: collection.isAwait,
        );
}

class GroupExpr extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitGroupExpr(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    inner.accept(visitor);
  }

  final ASTNode inner;

  GroupExpr(
    this.inner, {
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(
          InternalIdentifier.groupExpression,
          isAwait: inner.isAwait,
        );
}

abstract class TypeExpr extends ASTNode {
  bool get isLocal;

  TypeExpr(
    super.exprType, {
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  });
}

