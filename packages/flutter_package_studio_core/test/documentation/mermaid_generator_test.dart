import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('MermaidDiagramGenerator Unit Tests', () {
    late MermaidDiagramGenerator generator;

    setUp(() {
      generator = MermaidDiagramGenerator();
    });

    test('Generates valid flowchart TD diagram', () {
      final options = MermaidDiagramOptions(
        title: 'Flowchart Test',
        type: MermaidType.flowchartTD,
        nodes: const [
          MermaidNode(id: 'A', label: 'Node A'),
          MermaidNode(id: 'B', label: 'Node B'),
        ],
        edges: const [
          MermaidEdge(fromId: 'A', toId: 'B'),
        ],
      );

      final plan = generator.planDiagram(options);
      final result = generator.generateDiagram(plan);

      expect(result.source, contains('graph TD'));
      expect(result.source, contains('A[Node A] --> B[Node B]'));
    });

    test('Generates valid sequence diagram', () {
      final options = MermaidDiagramOptions(
        title: 'Sequence Test',
        type: MermaidType.sequenceDiagram,
        nodes: const [
          MermaidNode(id: 'User', label: 'User Client'),
          MermaidNode(id: 'Engine', label: 'Core Engine'),
        ],
        edges: const [
          MermaidEdge(fromId: 'User', toId: 'Engine', label: 'run()'),
        ],
      );

      final plan = generator.planDiagram(options);
      final result = generator.generateDiagram(plan);

      expect(result.source, contains('sequenceDiagram'));
      expect(result.source, contains('participant Engine as Core Engine'));
      expect(result.source, contains('User->>Engine: run()'));
    });

    test('Rejects invalid node IDs with special characters', () {
      final options = MermaidDiagramOptions(
        nodes: const [
          MermaidNode(id: 'Node-1!', label: 'Bad Node'),
        ],
      );

      expect(() => generator.planDiagram(options),
          throwsA(isA<MermaidGenerationException>()));
    });

    test('Rejects duplicate node IDs', () {
      final options = MermaidDiagramOptions(
        nodes: const [
          MermaidNode(id: 'A', label: 'Node A'),
          MermaidNode(id: 'A', label: 'Duplicate Node A'),
        ],
      );

      expect(() => generator.planDiagram(options),
          throwsA(isA<MermaidGenerationException>()));
    });

    test('Rejects edges referencing nonexistent nodes', () {
      final options = MermaidDiagramOptions(
        nodes: const [
          MermaidNode(id: 'A', label: 'Node A'),
        ],
        edges: const [
          MermaidEdge(fromId: 'A', toId: 'Nonexistent'),
        ],
      );

      expect(() => generator.planDiagram(options),
          throwsA(isA<MermaidGenerationException>()));
    });

    test('Output is 100% deterministic across repeated runs', () {
      final options = MermaidDiagramOptions(
        nodes: const [
          MermaidNode(id: 'B', label: 'Node B'),
          MermaidNode(id: 'A', label: 'Node A'),
        ],
        edges: const [
          MermaidEdge(fromId: 'A', toId: 'B'),
        ],
      );

      final plan1 = generator.planDiagram(options);
      final res1 = generator.generateDiagram(plan1);

      final plan2 = generator.planDiagram(options);
      final res2 = generator.generateDiagram(plan2);

      expect(res1.source, equals(res2.source));
    });
  });
}
