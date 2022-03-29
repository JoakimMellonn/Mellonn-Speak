module.exports = {
    mutation: `mutation UpdateRecording(
        $id: ID = "",
        $name: String = "",
        ) {
        updateRecording(input: {id: $id, name: $name}) {
          name
        }
      }
    `,
  };